// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as Char } from "./ICharacter.sol";

interface IMilitary {
    function joinTheArmy(Char.CharInfo calldata charInfo_) external;

    function equipItemsAndJoinTheArmy(Char.CharInfo memory charInfo_, uint256[] calldata itemIds_) external;

    function leaveTheArmy(uint256 charId_) external;

    function leaveTheArmyAndEquipGold(Char.CharInfo memory charInfo_) external;

    function modifyPower(uint256 charId_, uint256 powerChange_) external;

    function isCharEnlisted(uint256 charId_) external view returns (bool);
}
