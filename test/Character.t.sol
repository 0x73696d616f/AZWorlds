// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICharacter } from "../src/interfaces/ICharacter.sol";
import { Fixture } from "./Fixture.t.sol";
import { IItem } from "src/interfaces/IItem.sol";
import { Bank } from "src/Bank.sol";

contract CharacterTest is Fixture {
    function setUp() public virtual override {
        super.setUp();
    }

    function testEquipItems_ok() public {
        uint256[] memory itemIds_ = new uint256[](10);
        uint256 expectedPower_ = 1;
        for (uint256 i_ = 0; i_ < 10; i_++) {
            itemIds_[i_] = i_;
            _mintItem(_player1, i_);
            expectedPower_ += i_;
        }
        vm.prank(_player1);
        ICharacter(_character).equipItems(_player1CharId, itemIds_);
        (ICharacter.CharInfo memory charInfo_,) = ICharacter(_character).getCharInfo(_player1CharId);
        assertEq(charInfo_.power, expectedPower_);
        for (uint256 i_ = 0; i_ < 10; i_++) {
            assertEq(IItem(_item).balanceOf(_player1, i_), 0);
        }
    }

    function testCarryGold_ok() public {
        _carryGold(100);
    }

    function testDropGold_ok() public {
        uint256 gold_ = 100;
        _carryGold(gold_);
        vm.prank(_player1);
        ICharacter(_character).dropGold(_player1CharId, gold_);
        (ICharacter.CharInfo memory charInfo_,) = ICharacter(_character).getCharInfo(_player1CharId);
        assertEq(charInfo_.equippedGold, 0);
        assertEq(Bank(_bank).balanceOf(_player1), 100);
    }

    function _carryGold(uint256 gold_) internal {
        _mintGold(_player1, gold_);
        assertEq(Bank(_bank).balanceOf(_player1), gold_);
        vm.prank(_player1);
        ICharacter(_character).carryGold(_player1CharId, gold_);
        (ICharacter.CharInfo memory charInfo_,) = ICharacter(_character).getCharInfo(_player1CharId);
        assertEq(charInfo_.equippedGold, gold_);
        assertEq(Bank(_bank).balanceOf(_player1), 0);
    }
}
