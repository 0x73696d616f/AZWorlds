// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IONFT721 } from "src/dependencies/layerZero/interfaces/onft721/IONFT721.sol";

interface ICharacter is IONFT721 {
    struct CharInfo {
        uint256 charId;
        uint256 level;
        uint256 power;
        uint256 equippedGold;
        bytes equippedItems;
    }

    function equipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external;

    function unequipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external;

    function carryGold(CharInfo memory charInfo_, uint256 gold_) external;

    function dropGold(CharInfo memory charInfo_, uint256 gold_) external;

    function validateCharInfo(CharInfo calldata charInfo_, uint256 charId_) external;
}
