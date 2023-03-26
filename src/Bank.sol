// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IInvestmentStrategy } from "src/interfaces/IInvestmentStrategy.sol";
import { IBank } from "src/interfaces/IBank.sol";
import { Gold } from "src/Gold.sol";

contract Bank is IBank, ERC4626, Gold {
    IInvestmentStrategy public investmentStrategy;
    address public governance;

    constructor(address character_, address marketplace_, address lzEndpoint_, IERC20 asset_, address governance_)
        Gold(character_, marketplace_, lzEndpoint_)
        ERC4626(asset_)
    {
        governance = governance_;
    }

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    function depositAndNotify(uint256 amount_, address to_, bytes calldata data) external override {
        deposit(amount_, to_);
        to_.call(data);
    }

    function decimals() public pure override(ERC20, ERC4626, IERC20Metadata) returns (uint8) {
        return 18;
    }

    function invest(uint256 amount_) public override onlyGovernance {
        IERC20(asset()).transfer(address(investmentStrategy), amount_);
        investmentStrategy.invest(amount_);
    }

    function withdrawInvestment(uint256 amount_) external override onlyGovernance returns (uint256 rewards_) {
        rewards_ = investmentStrategy.withdraw(amount_);
    }

    function claimRewards() external override returns (uint256 rewards_) {
        rewards_ = investmentStrategy.claimRewards();
    }

    function setInvestmentStrategy(IInvestmentStrategy strategy_) external override onlyGovernance {
        investmentStrategy = strategy_;
    }

    function previewRewards() external view override returns (uint256) {
        return investmentStrategy.previewRewards();
    }

    function getInvestment() external view override returns (uint256) {
        return investmentStrategy.getTotalStaked();
    }

    function _onlyGovernance() internal view {
        if (msg.sender != governance) revert NotGovernanceError(msg.sender);
    }
}
