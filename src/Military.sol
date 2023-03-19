// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IMilitary } from "./interfaces/IMilitary.sol";
import { Character as Char } from "./Character.sol";

contract Military is IMilitary {
    function joinTheArmy(Char.CharInfo calldata charInfo_) external override { }

    function equipItemsAndJoinTheArmy(Char.CharInfo memory charInfo_, uint256[] calldata itemIds_) external override { }

    function leaveTheArmy(uint256 charId_) external override { }

    function leaveTheArmyAndEquipGold(Char.CharInfo memory charInfo_) external override { }

    function modifyPower(uint256 charId_, uint256 powerChange_) external override { }

    function isCharEnlisted(uint256 charId_) external view override returns (bool) { }
}
