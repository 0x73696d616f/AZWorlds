// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { console } from "@forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Fixture } from "./Fixture.t.sol";
import { IBank } from "src/interfaces/IBank.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract BankTest is Fixture {
    function setUp() public virtual override {
        super.setUp();
    }

    function testInvest_ok() public {
        _invest(100);
    }

    function testRewards() public {
        uint256 amount_ = IERC20(_usdc).balanceOf(_bank);
        _invest(amount_);
        assertEq(IBank(_bank).previewRewards(), 0);
        vm.warp(365 days + 1);
        assertEq(IBank(_bank).totalAssets() + IBank(_bank).previewRewards(), amount_ * 105 / 100);

        vm.prank(_military);
        IBank(_bank).withdraw(amount_ * 105 / 100 - 1, _military, _military); //rounds down

        assertEq(IBank(_bank).previewRewards(), 0);
        assertEq(IBank(_bank).totalAssets(), 1);

        vm.prank(_military);
        IERC20(_usdc).approve(_bank, type(uint256).max);
        vm.prank(_military);
        IBank(_bank).deposit(amount_ * 105 / 100 - 1, _military);
        vm.prank(_deployer);
        IBank(_bank).invest(amount_ * 105 / 100 - 1);

        vm.warp(2 * 365 days + 1);

        uint256 militaryShares_ = IBank(_bank).balanceOf(_military);
        vm.prank(_military);
        IBank(_bank).redeem(militaryShares_, _military, _military);
        assertEq(IERC20(_usdc).balanceOf(_military), (amount_ * 105 / 100 - 1) * 105 / 100);

        assertEq(IBank(_bank).previewRewards(), 0);
        assertEq(IBank(_bank).totalAssets(), 2);
    }

        function testEIP() public {
            console.log(vm.toString(MockERC20(_usdc).DOMAIN_SEPARATOR()));
        }

    function _invest(uint256 usdcAmount_) internal {
        uint256 initialUsdcBalance_ = IERC20(_usdc).balanceOf(_investmentProtocol);
        vm.prank(_deployer);
        IBank(_bank).invest(usdcAmount_);
        assertEq(IERC20(_usdc).balanceOf(_investmentProtocol), initialUsdcBalance_ + usdcAmount_);
    }
}
