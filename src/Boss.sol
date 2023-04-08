// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBase } from "src/dependencies/chainlink/VRFV2WrapperConsumerBase.sol";
import { Babylonian } from "src/dependencies/Babylonian.sol";
import { IItem } from "./interfaces/IItem.sol";
import { ICharacter as IChar } from "./interfaces/ICharacter.sol";
import { IBoss } from "./interfaces/IBoss.sol";

contract Boss is IBoss, VRFV2WrapperConsumerBase {
    uint256 public immutable ROUND_DURATION;
    uint256 public constant MAX_ITEM_ID = 4999;
    uint256 public immutable MAX_NUMBER_SQRT;

    mapping(uint256 => mapping(uint256 => Round)) public charInfo;
    mapping(uint256 => uint256) public roundSeed;
    uint256 public lastRoundTimestamp = block.timestamp;
    uint256 public roundId;
    IItem public _item;
    IChar public _char;

    constructor(IItem item_, IChar char_, address link_, address vrfV2Wrapper_, uint256 roundDuration_)
        VRFV2WrapperConsumerBase(link_, vrfV2Wrapper_)
    {
        _item = item_;
        _char = char_;
        MAX_NUMBER_SQRT = Babylonian.sqrt(type(uint256).max);
        ROUND_DURATION = roundDuration_;
    }

    function attackBoss(uint256 charId_) external override {
        if (_char.ownerOf(charId_) != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
        charInfo[roundId][charId_].attacked = true;
        emit BossAttacked(roundId, charId_);
    }

    function claimRewards(uint256 charId_, uint256 roundId_) external override returns (uint256 itemId_) {
        uint256 seed_ = roundSeed[roundId_];
        if (seed_ == 0) revert RoundNotOverError(roundId_);
        if (_char.ownerOf(charId_) != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
        if (!charInfo[roundId_][charId_].attacked) revert AlreadyAttackedError(charId_, roundId_);
        if (charInfo[roundId_][charId_].claimed) revert AlreadyClaimedError(charId_, roundId_);

        itemId_ = MAX_ITEM_ID
            - MAX_ITEM_ID * Babylonian.sqrt(uint256(keccak256(abi.encodePacked(seed_, charId_)))) / MAX_NUMBER_SQRT;
        _item.mint(msg.sender, itemId_);
        charInfo[roundId_][charId_].claimed = true;
        _char.levelUp(charId_);
        emit RewardClaimed(roundId_, charId_, itemId_);
    }

    function previewRewards(uint256 charId_, uint256 roundId_) external view override returns (uint256 itemId_) {
        itemId_ = MAX_ITEM_ID
            - MAX_ITEM_ID * Babylonian.sqrt(uint256(keccak256(abi.encodePacked(roundSeed[roundId_], charId_))))
                / MAX_NUMBER_SQRT;
    }

    function nextRound() public override {
        if (block.timestamp - lastRoundTimestamp < ROUND_DURATION) return;
        ++roundId;
        lastRoundTimestamp = block.timestamp;
        requestRandomness(100_000, 10, 1);
        emit RoundStarted(roundId, block.timestamp);
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords) internal override {
        roundSeed[roundId - 1] = _randomWords[0];
        emit RandomWordsFulfilled(roundId, _randomWords[0]);
    }
}
