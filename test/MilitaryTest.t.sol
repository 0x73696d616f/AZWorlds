// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Fixture } from "./Fixture.t.sol";
import { IMilitary } from "src/interfaces/IMilitary.sol";
import { IGold } from "src/interfaces/IGold.sol";
import { ICharacter } from "src/interfaces/ICharacter.sol";
import { Boss } from "src/Boss.sol";
import { IBoss } from "src/interfaces/IBoss.sol";

contract MilitaryTest is Fixture {
    function setUp() public virtual override {
        super.setUp();
    }

    function testJoinMilitary_ok() public {
        uint256 initialBalance_ = IGold(_addrs.bank).balanceOf(_addrs.military);
        vm.prank(_player1);
        IMilitary(_addrs.military).join(_player1CharId);
        vm.warp(365 days + 1);
        vm.prank(_player1);
        uint256 rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertEq(rewards_, initialBalance_);
        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 0);

        vm.prank(_player1);
        vm.expectRevert(abi.encodeWithSelector(IMilitary.AlreadyEnlistedError.selector, _player1CharId));
        IMilitary(_addrs.military).join(_player1CharId);

        vm.prank(_player1);
        IMilitary(_addrs.military).leave(_player1CharId);

        vm.warp(2 * 365 days + 1);

        vm.prank(_player1);
        rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertEq(rewards_, 0);
    }

    function testJoinMilitary_noPowerBurnsAll() public {
        uint256 initialBalance_ = IGold(_addrs.bank).balanceOf(_addrs.military);
        vm.warp(365 days + 1);
        vm.prank(_player1);
        IMilitary(_addrs.military).join(_player1CharId);
        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 0);
    }

    function testMilitary_halfPower() public {
        address player2_ = vm.addr(4);
        uint256 player2CharId_ = _buyCharacter(player2_, 4);

        uint256 initialBalance_ = IGold(_addrs.bank).balanceOf(_addrs.military);
        vm.prank(_player1);
        IMilitary(_addrs.military).join(_player1CharId);
        vm.prank(player2_);
        IMilitary(_addrs.military).join(player2CharId_);
        vm.warp(365 days + 1);
        vm.prank(_player1);
        uint256 rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertEq(rewards_, initialBalance_ / 2);
        vm.prank(player2_);
        rewards_ = IMilitary(_addrs.military).getRewards(player2CharId_);
        assertEq(rewards_, initialBalance_ / 2);

        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 0);

        vm.warp(2 * 365 days + 1);
        vm.prank(_player1);
        rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertEq(rewards_, 0);
        vm.prank(player2_);
        rewards_ = IMilitary(_addrs.military).getRewards(player2CharId_);
        assertEq(rewards_, 0);

        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 0);
    }

    function testMilitary_powerIncrease() public {
        address player2_ = vm.addr(4);
        uint256 player2CharId_ = _buyCharacter(player2_, 4);
        _mintItem(player2_, 1);
        vm.prank(player2_);
        uint256[] memory itemIds_ = new uint256[](1);
        itemIds_[0] = 1;
        ICharacter(_addrs.character).equipItems(player2CharId_, itemIds_);

        uint256 initialBalance_ = IGold(_addrs.bank).balanceOf(_addrs.military);
        vm.prank(_player1);
        IMilitary(_addrs.military).join(_player1CharId);
        vm.prank(player2_);
        IMilitary(_addrs.military).join(player2CharId_);
        vm.warp(365 days + 1);
        vm.prank(_player1);
        uint256 rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertLe(rewards_, initialBalance_ / 2);
        vm.prank(player2_);
        rewards_ = IMilitary(_addrs.military).getRewards(player2CharId_);
        assertGe(rewards_, initialBalance_ / 2);

        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 1); // rounding error

        vm.warp(2 * 365 days + 1);
        vm.prank(_player1);
        rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertEq(rewards_, 0);
        vm.prank(player2_);
        rewards_ = IMilitary(_addrs.military).getRewards(player2CharId_);
        assertEq(rewards_, 0);

        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 1);
    }

    function testMilitary_fightBoss_powerIncrease() public {
        address player2_ = vm.addr(4);
        uint256 player2CharId_ = _buyCharacter(player2_, 4);
        vm.prank(player2_);
        IBoss(_addrs.boss).attackBoss(player2CharId_);
        vm.warp(Boss(_addrs.boss).ROUND_DURATION());
        vm.prank(_addrsExt.vrf2Wrapper);
        uint256[] memory itemId_ = new uint256[](1);
        itemId_[0] = type(uint256).max / 2;
        IBoss(_addrs.boss).rawFulfillRandomWords(0, itemId_);
        vm.prank(player2_);
        IBoss(_addrs.boss).claimRewards(player2CharId_, 0);

        uint256 initialBalance_ = IGold(_addrs.bank).balanceOf(_addrs.military);
        vm.prank(_player1);
        IMilitary(_addrs.military).join(_player1CharId);
        vm.prank(player2_);
        IMilitary(_addrs.military).join(player2CharId_);

        vm.warp(365 days + 1);
        vm.prank(_player1);
        uint256 rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertLe(rewards_, initialBalance_ / 2);
        vm.prank(player2_);
        rewards_ = IMilitary(_addrs.military).getRewards(player2CharId_);
        assertGe(rewards_, initialBalance_ / 2);

        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 2); // rounding error

        vm.warp(2 * 365 days + 1);
        vm.prank(_player1);
        rewards_ = IMilitary(_addrs.military).getRewards(_player1CharId);
        assertEq(rewards_, 0);
        vm.prank(player2_);
        rewards_ = IMilitary(_addrs.military).getRewards(player2CharId_);
        assertEq(rewards_, 0);

        assertEq(IGold(_addrs.bank).balanceOf(_addrs.military), 2);
    }
}