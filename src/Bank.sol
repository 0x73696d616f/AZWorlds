// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import { IBank } from "src/interfaces/IBank.sol";
import { Gold } from "src/Gold.sol";

contract Bank is IBank, ERC4626, Gold {
    constructor(address character_, address lzEndpoint_, IERC20 asset_) Gold(character_, lzEndpoint_) ERC4626(asset_) { }

    function decimals() public pure override(ERC20, ERC4626, IERC20Metadata) returns (uint8) {
        return 18;
    }

    function invest(uint256 amount_) external override { }

    function withdrawInvestment(uint256 amount_) external override { }

    function claimRewards() external override { }

    function setInvestmentStrategy(address strategy_) external override { }

    function getRewards() external view override returns (uint256) { }

    function getInvestment() external view override returns (uint256) { }

    function getInvestmentStrategy() external view override returns (address) { }
}
