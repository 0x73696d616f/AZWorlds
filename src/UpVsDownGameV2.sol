// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGold } from "./interfaces/IGold.sol";
import { IPriceFeed } from "./interfaces/IPriceFeed.sol";

contract UpVsDownGameV2 is Ownable {
    struct BetGroup {
        uint256[] bets;
        address[] addresses;
        string[] avatars;
        string[] countries;
        uint256 total;
        uint256 distributedCount;
        uint256 totalDistributed;
    }

    struct Round {
        bool created;
        int32 startPrice;
        int32 endPrice;
        uint256 minBetAmount;
        uint256 maxBetAmount;
        uint256 poolBetsLimit;
        BetGroup upBetGroup;
        BetGroup downBetGroup;
        int64 roundStartTime;
    }

    struct Distribution {
        uint256 fee;
        uint256 totalMinusFee;
        uint256 pending;
    }

    int32 public GAME_DURATION = 30;
    address public gameController;
    mapping(bytes => Round) public pools;
    uint256 public feePercentage = 5;
    bool public isRunning;
    bytes public notRunningReason;

    IGold public immutable gold;
    IPriceFeed public immutable priceFeed;
    IERC20 public immutable WBTC;
    IERC20 public immutable usdc;

    mapping(address => uint256) public lostGold;

    // Errors

    error PendingDistributions();

    // Events

    event RoundStarted(
        bytes poolId,
        int64 timestamp,
        int32 price,
        uint256 minTradeAmount,
        uint256 maxTradeAmount,
        uint256 poolTradesLimit,
        bytes indexed indexedPoolId
    );
    event RoundEnded(bytes poolId, int64 timestamp, int32 startPrice, int32 endPrice, bytes indexed indexedPoolId);
    event TradePlaced(
        bytes poolId,
        address sender,
        uint256 amount,
        string prediction,
        uint256 newTotal,
        bytes indexed indexedPoolId,
        address indexed indexedSender,
        string avatarUrl,
        string countryCode,
        int64 roundStartTime
    );
    event TradeReturned(bytes poolId, address sender, uint256 amount);
    event GameStopped(bytes reason);
    event GameStarted();
    event RoundDistributed(bytes poolId, uint256 totalWinners, uint256 from, uint256 to, int64 timestamp);
    event TradeWinningsSent(
        bytes poolId, address sender, uint256 tradeAmount, uint256 winningsAmount, address indexed indexedSender
    );

    // Modifiers

    modifier onlyGameController() {
        require(msg.sender == gameController, "Only game controller can do this");
        _;
    }

    modifier onlyOpenPool(bytes calldata poolId) {
        require(isPoolOpen(poolId), "This pool has a round in progress");
        _;
    }

    modifier onlyGameRunning() {
        require(isRunning, "The game is not running");
        _;
    }

    modifier onlyPoolExists(bytes calldata poolId) {
        require(pools[poolId].created == true, "Pool does not exist");
        _;
    }

    constructor(IGold gold_, IPriceFeed oneInchPriceFeed_, IERC20 WBTC_, IERC20 usdc_) {
        gold = gold_;
        priceFeed = oneInchPriceFeed_;
        WBTC = WBTC_;
        usdc = usdc_;
        gameController = msg.sender;
    }

    // Methods

    function changeGameDuration(int32 newGameDuration) public onlyOwner {
        require(newGameDuration != 0, "Game duration cannot be 0");
        GAME_DURATION = newGameDuration;
    }

    function changeGameControllerAddress(address newGameController) public onlyOwner {
        gameController = newGameController;
    }

    function changeGameFeePercentage(uint256 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
    }

    function stopGame(bytes calldata reason) public onlyOwner {
        isRunning = false;
        notRunningReason = reason;
        emit GameStopped(reason);
    }

    function startGame() public onlyOwner {
        isRunning = true;
        notRunningReason = "";
        emit GameStarted();
    }

    function createPool(bytes calldata poolId, uint256 minBetAmount, uint256 maxBetAmount, uint256 poolBetsLimit)
        public
        onlyGameController
    {
        pools[poolId].created = true;
        pools[poolId].minBetAmount = minBetAmount;
        pools[poolId].maxBetAmount = maxBetAmount;
        pools[poolId].poolBetsLimit = poolBetsLimit;
    }

    function trigger(bytes calldata poolId, uint32 batchSize) public onlyPoolExists(poolId) {
        Round storage currentRound = pools[poolId];

        if (isPoolOpen(poolId) && int64(uint64(block.timestamp)) > currentRound.roundStartTime + 2 * GAME_DURATION) {
            require(isRunning, "The game is not running, rounds can only be ended at this point");
            currentRound.startPrice = int32(uint32(priceFeed.getRate(WBTC, usdc, true)));
            currentRound.roundStartTime = int64(uint64(block.timestamp));

            emit RoundStarted(
                poolId,
                int64(uint64(block.timestamp)),
                currentRound.startPrice,
                currentRound.minBetAmount,
                currentRound.maxBetAmount,
                currentRound.poolBetsLimit,
                poolId
            );
        } else if (
            currentRound.endPrice == 0 && int64(uint64(block.timestamp)) > currentRound.roundStartTime + GAME_DURATION
        ) {
            require(tx.origin == msg.sender, "Only EOA");
            currentRound.endPrice = int32(uint32(priceFeed.getRate(WBTC, usdc, true)));

            emit RoundEnded(
                poolId, int64(uint64(block.timestamp)), currentRound.startPrice, currentRound.endPrice, poolId
            );

            distribute(poolId, batchSize);
        } else {
            revert PendingDistributions();
        }
    }

    function returnBets(bytes calldata poolId, BetGroup storage group, uint32 batchSize) private {
        uint256 pending = group.bets.length - group.distributedCount;
        uint256 limit = pending > batchSize ? batchSize : pending;
        uint256 to = group.distributedCount + limit;

        for (uint256 i = group.distributedCount; i < to; i++) {
            bool success = sendGold(group.addresses[i], group.bets[i]);
            if (success) emit TradeReturned(poolId, group.addresses[i], group.bets[i]);
        }

        group.distributedCount = to;
    }

    function distribute(bytes calldata poolId, uint32 batchSize) public onlyPoolExists(poolId) {
        Round storage round = pools[poolId];

        if (round.upBetGroup.bets.length == 0 || round.downBetGroup.bets.length == 0) {
            BetGroup storage returnGroup = round.downBetGroup.bets.length == 0 ? round.upBetGroup : round.downBetGroup;

            uint256 fromReturn = returnGroup.distributedCount;
            returnBets(poolId, returnGroup, batchSize);
            emit RoundDistributed(
                poolId,
                returnGroup.bets.length,
                fromReturn,
                returnGroup.distributedCount,
                int64(uint64(block.timestamp))
            );

            if (returnGroup.distributedCount == returnGroup.bets.length) {
                clearPool(poolId);
            }
            return;
        }

        BetGroup storage winners = round.downBetGroup;
        BetGroup storage losers = round.upBetGroup;

        if (round.startPrice < round.endPrice) {
            winners = round.upBetGroup;
            losers = round.downBetGroup;
        }

        Distribution memory dist = calculateDistribution(winners, losers);
        uint256 limit = dist.pending > batchSize ? batchSize : dist.pending;
        uint256 to = winners.distributedCount + limit;

        for (uint256 i = winners.distributedCount; i < to; i++) {
            uint256 winnings = ((winners.bets[i] * 100 / winners.total) * dist.totalMinusFee / 100);
            bool success = sendGold(winners.addresses[i], winnings + winners.bets[i]);
            if (success) {
                emit TradeWinningsSent(poolId, winners.addresses[i], winners.bets[i], winnings, winners.addresses[i]);
            }
            winners.totalDistributed = winners.totalDistributed + winnings;
        }

        emit RoundDistributed(poolId, winners.bets.length, winners.distributedCount, to, int64(uint64(block.timestamp)));

        winners.distributedCount = to;
        if (winners.distributedCount == winners.bets.length) {
            sendGold(gameController, dist.fee + dist.totalMinusFee - winners.totalDistributed);
            clearPool(poolId);
        }
    }

    function calculateDistribution(BetGroup storage winners, BetGroup storage losers)
        private
        view
        returns (Distribution memory)
    {
        uint256 fee = feePercentage * losers.total / 100;
        uint256 pending = winners.bets.length - winners.distributedCount;
        return Distribution({ fee: fee, totalMinusFee: losers.total - fee, pending: pending });
    }

    function clearPool(bytes calldata poolId) private {
        delete pools[poolId].upBetGroup;
        delete pools[poolId].downBetGroup;
        delete pools[poolId].startPrice;
        delete pools[poolId].endPrice;
    }

    function hasPendingDistributions(bytes calldata poolId) public view returns (bool) {
        return (pools[poolId].upBetGroup.bets.length + pools[poolId].downBetGroup.bets.length) > 0;
    }

    function isPoolOpen(bytes calldata poolId) public view returns (bool) {
        return pools[poolId].startPrice == 0;
    }

    function addBet(BetGroup storage betGroup, uint256 amount, string calldata avatar, string calldata countryCode)
        private
        returns (uint256)
    {
        betGroup.bets.push(amount);
        betGroup.addresses.push(msg.sender);
        betGroup.avatars.push(avatar);
        betGroup.countries.push(countryCode);
        betGroup.total += amount;
        return betGroup.total;
    }

    struct makeTradeStruct {
        bytes poolId;
        string avatarUrl;
        string countryCode;
        bool upOrDown;
        uint256 goldBet;
    }

    function makeTrade(makeTradeStruct calldata userTrade)
        public
        payable
        onlyOpenPool(userTrade.poolId)
        onlyGameRunning
        onlyPoolExists(userTrade.poolId)
    {
        gold.privilegedTransferFrom(msg.sender, address(this), userTrade.goldBet);
        require(userTrade.goldBet > 0, "Needs to send Gold to trade");
        require(
            userTrade.goldBet >= pools[userTrade.poolId].minBetAmount, "Trade amount should be higher than the minimum"
        );
        require(
            userTrade.goldBet <= pools[userTrade.poolId].maxBetAmount, "Trade amount should be lower than the maximum"
        );
        uint256 newTotal;

        if (userTrade.upOrDown) {
            require(
                pools[userTrade.poolId].upBetGroup.bets.length <= pools[userTrade.poolId].poolBetsLimit - 1,
                "Pool is full, wait for next round"
            );
            newTotal = addBet(
                pools[userTrade.poolId].upBetGroup, userTrade.goldBet, userTrade.avatarUrl, userTrade.countryCode
            );
        } else {
            require(
                pools[userTrade.poolId].downBetGroup.bets.length <= pools[userTrade.poolId].poolBetsLimit - 1,
                "Pool is full, wait for next round"
            );
            newTotal = addBet(
                pools[userTrade.poolId].downBetGroup, userTrade.goldBet, userTrade.avatarUrl, userTrade.countryCode
            );
        }

        string memory avatar;
        {
            avatar = userTrade.avatarUrl;
        }

        string memory countryCode;
        {
            countryCode = userTrade.countryCode;
        }

        int64 roundStartTime;
        {
            roundStartTime = pools[userTrade.poolId].roundStartTime;
        }

        emit TradePlaced(
            userTrade.poolId,
            msg.sender,
            userTrade.goldBet,
            (userTrade.upOrDown) ? "UP" : "DOWN",
            newTotal,
            userTrade.poolId,
            msg.sender,
            avatar,
            countryCode,
            roundStartTime
        );
    }

    function claimLostGold() external {
        uint256 amount = lostGold[msg.sender];
        lostGold[msg.sender] = 0;
        sendGold(msg.sender, amount);
    }

    function sendGold(address to, uint256 amount) private returns (bool success) {
        try gold.transfer(to, amount) {
            success = true;
        } catch {
            lostGold[to] += amount;
        }
    }
}
