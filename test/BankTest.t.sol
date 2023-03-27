// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { console } from "@forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Fixture } from "./Fixture.t.sol";
import { IBank } from "src/interfaces/IBank.sol";

contract BankTest is Fixture {
    function setUp() public virtual override {
        super.setUp();
    }

    function testInvest_ok() public {
        _invest(100);
    }

    function testRewards() public {
        uint256 amount_ = IERC20(_addrsExt.usdc).balanceOf(_addrs.bank);
        _invest(amount_);
        assertEq(IBank(_addrs.bank).previewRewards(), 0);
        assertEq(IBank(_addrs.bank).claimRewards(), 0);
        vm.warp(365 days + 1);
        assertEq(IBank(_addrs.bank).previewRewards(), amount_ * 5 / 100);
        assertEq(IBank(_addrs.bank).claimRewards(), amount_ * 5 / 100);
        assertEq(IBank(_addrs.bank).totalAssets(), amount_ * 105 / 100);

        vm.prank(_addrs.military);
        vm.expectRevert();
        IBank(_addrs.bank).withdraw(amount_ * 5 / 100 + 1, _addrs.military, _addrs.military);

        // Can only withdraw rewards
        vm.prank(_addrs.military);
        IBank(_addrs.bank).withdraw(amount_ * 5 / 100, _addrs.military, _addrs.military);

        // Remove investment
        vm.prank(_deployer);
        IBank(_addrs.bank).withdrawInvestment(amount_);

        // Now can withdraw everything
        vm.prank(_addrs.military);
        IBank(_addrs.bank).withdraw(amount_ - 1, _addrs.military, _addrs.military); //rounds down
    }

    function _invest(uint256 usdcAmount_) internal {
        uint256 initialUsdcBalance_ = IERC20(_addrsExt.usdc).balanceOf(_addrs.investmentProtocol);
        vm.prank(_deployer);
        IBank(_addrs.bank).invest(usdcAmount_);
        assertEq(IERC20(_addrsExt.usdc).balanceOf(_addrs.investmentProtocol), initialUsdcBalance_ + usdcAmount_);
    }
}
