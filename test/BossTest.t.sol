// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { console } from "@forge-std/console.sol";
import { Fixture } from "./Fixture.t.sol";
import { Boss } from "src/Boss.sol";
import { IBoss } from "src/interfaces/IBoss.sol";
import { IItem } from "src/interfaces/IItem.sol";

contract BossTest is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function testAttack_ok() public {
        vm.prank(_player1);
        Boss(_addrs.boss).attackBoss(_player1CharId);
        vm.warp(_cts.bossRoundDuration);
        vm.prank(_player1);
        Boss(_addrs.boss).attackBoss(_player1CharId);
        vm.prank(_addrsExt.vrf2Wrapper);
        uint256[] memory itemId_ = new uint256[](1);
        itemId_[0] = type(uint256).max / 2;
        IBoss(_addrs.boss).rawFulfillRandomWords(0, itemId_);
        vm.prank(_player1);
        uint256 receivedItemId_ = Boss(_addrs.boss).claimRewards(_player1CharId, 0);
        assertEq(IItem(_addrs.item).balanceOf(_player1, receivedItemId_), 1);
    }

    function testAttack_RoundNotOver() public {
        vm.startPrank(_player1);
        Boss(_addrs.boss).attackBoss(_player1CharId);
        vm.expectRevert(abi.encodeWithSelector(IBoss.RoundNotOverError.selector, 0));
        Boss(_addrs.boss).claimRewards(_player1CharId, 0);
        vm.stopPrank();
    }
}
