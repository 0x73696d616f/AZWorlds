// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as Char } from "src/interfaces/ICharacter.sol";

library CharacterActionsLib {
    function equipItems(Char.CharInfo memory charInfo_, uint256[] calldata itemIds_) external { }

    function unequipItems(Char.CharInfo memory charInfo_, uint256[] calldata itemIds_) external { }

    function carryGold(Char.CharInfo memory charInfo_, uint256 gold_) external { }

    function dropGold(Char.CharInfo memory charInfo_, uint256 gold_) external { }

    function validateCharInfo(Char.CharInfo calldata charInfo_, uint256 charId_) external { }
}
