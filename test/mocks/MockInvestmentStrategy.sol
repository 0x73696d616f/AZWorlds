// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { InvestmentStrategy } from "src/InvestmentStrategy.sol";
import { Bank } from "src/Bank.sol";
import { MockInvestmentProtocol } from "test/mocks/MockInvestmentProtocol.sol";

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract MockInvestmentStrategy is InvestmentStrategy {
    MockInvestmentProtocol public immutable protocol;
    IERC20 public immutable bankAsset;
    IERC20 public immutable rewardToken;
    ISwapRouter public immutable swapRouter;
    uint24 public immutable poolFee;

    constructor(Bank bank_, MockInvestmentProtocol protocol_, ISwapRouter swapRouter_, uint24 poolFee_)
        InvestmentStrategy(bank_)
    {
        bank = bank_;
        protocol = protocol_;
        swapRouter = swapRouter_;
        poolFee = poolFee_;
        rewardToken = protocol_.rewardToken();
        rewardToken.approve(address(swapRouter), type(uint256).max);
        bankAsset = IERC20(bank_.asset());
        bankAsset.approve(address(protocol), type(uint256).max);
    }

    function invest(uint256 amount_) external override onlyBank {
        protocol.stake(amount_);
    }

    function claimRewards() external override onlyBank returns (uint256 rewards_) {
        rewards_ = protocol.claimRewards();
        _swapRewardTokensForBankAssetAndSendToBank();
    }

    function previewRewards() external view override returns (uint256 rewards_) {
        rewards_ = protocol.previewRewards();
    }

    function withdraw(uint256 amount_) external override onlyBank returns (uint256 rewards_) {
        rewards_ = protocol.withdraw(amount_);
        bankAsset.transfer(address(bank), amount_);
    }

    function getTotalStaked() external view override returns (uint256) {
        return protocol.getTotalStaked();
    }

    function _swapRewardTokensForBankAssetAndSendToBank() internal {
        uint256 rewardsBalance_ = rewardToken.balanceOf(address(this));
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(rewardToken),
            tokenOut: address(bankAsset),
            fee: poolFee,
            recipient: address(bank),
            deadline: block.timestamp,
            amountIn: rewardsBalance_,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        swapRouter.exactInputSingle(swapParams);
    }
}
