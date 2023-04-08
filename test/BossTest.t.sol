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
        Boss(_boss).attackBoss(_player1CharId);
        vm.warp(_bossRoundDuration + block.timestamp);
        vm.prank(_player1);
        vm.store(_boss, bytes32(uint256(3)), bytes32(uint256(1)));
        assertEq(Boss(_boss).roundId(), 1);
        uint256[] memory itemId_ = new uint256[](1);
        itemId_[0] = type(uint256).max / 2;
        vm.prank(_vrf2Wrapper);
        IBoss(_boss).rawFulfillRandomWords(0, itemId_);
        vm.prank(_player1);
        uint256 receivedItemId_ = Boss(_boss).claimRewards(_player1CharId, 0);
        assertEq(IItem(_item).balanceOf(_player1, receivedItemId_), 1);
    }

    function testAttack_RoundNotOver() public {
        vm.startPrank(_player1);
        Boss(_boss).attackBoss(_player1CharId);
        vm.expectRevert(abi.encodeWithSelector(IBoss.RoundNotOverError.selector, 0));
        Boss(_boss).claimRewards(_player1CharId, 0);
        vm.stopPrank();
    }
}
