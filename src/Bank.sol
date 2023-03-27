// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IInvestmentStrategy } from "src/interfaces/IInvestmentStrategy.sol";
import { IBank } from "src/interfaces/IBank.sol";
import { IMilitary } from "src/interfaces/IMilitary.sol";
import { Gold } from "src/Gold.sol";

contract Bank is IBank, ERC4626, Gold {
    uint256 public totalUsdc;
    address public military;

    IInvestmentStrategy public investmentStrategy;

    constructor(
        address character_,
        address marketplace_,
        address military_,
        address lzEndpoint_,
        IERC20 asset_,
        address game_
    ) Gold(character_, marketplace_, lzEndpoint_, game_) ERC4626(asset_) {
        military = military_;
    }

    function depositAndSendToMilitary(uint256 assets_) external override {
        uint256 shares_ = deposit(assets_, military);
        IMilitary(military).deposit(shares_);
    }

    function decimals() public pure override(ERC20, ERC4626, IERC20Metadata) returns (uint8) {
        return 18;
    }

    function invest(uint256 amount_) public override onlyOwner {
        IERC20(asset()).transfer(address(investmentStrategy), amount_);
        investmentStrategy.invest(amount_);
    }

    function withdrawInvestment(uint256 amount_) external override onlyOwner {
        investmentStrategy.withdraw(amount_);
    }

    function _claimRewards() internal returns (uint256 rewards_) {
        rewards_ = investmentStrategy.claimRewards();
        if (rewards_ > 0) totalUsdc += rewards_;
    }

    function setInvestmentStrategy(IInvestmentStrategy strategy_) external override onlyOwner {
        investmentStrategy = strategy_;
    }

    function previewRewards() external view override returns (uint256) {
        return investmentStrategy.previewRewards();
    }

    function getInvestment() external view override returns (uint256) {
        return investmentStrategy.getTotalStaked();
    }

    function totalAssets() public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return totalUsdc;
    }

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(ERC4626, IERC4626)
        returns (uint256 shares_)
    {
        _claimRewards();
        shares_ = super.deposit(assets, receiver);
        totalUsdc += assets;
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        override(ERC4626, IERC4626)
        returns (uint256 assets_)
    {
        _claimRewards();
        assets_ = super.mint(shares, receiver);
        totalUsdc += assets_;
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override(ERC4626, IERC4626)
        returns (uint256 shares_)
    {
        _claimRewards();
        _withdrawInvestmentToAllowWithdrawal(assets);
        shares_ = super.withdraw(assets, receiver, owner);
        totalUsdc -= assets;
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override(ERC4626, IERC4626)
        returns (uint256 assets_)
    {
        _claimRewards();
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");
        assets_ = previewRedeem(shares);
        _withdrawInvestmentToAllowWithdrawal(assets_);
        super.redeem(shares, receiver, owner);
        totalUsdc -= assets_;
    }

    function _withdrawInvestmentToAllowWithdrawal(uint256 assets_) internal {
        uint256 notInvestedAssets_ = IERC20(asset()).balanceOf(address(this));
        if (assets_ > notInvestedAssets_) investmentStrategy.withdraw(assets_ - notInvestedAssets_);
    }
}
