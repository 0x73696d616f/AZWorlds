// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as Char } from "./ICharacter.sol";

interface IMarketplace {
    struct Order {
        address seller;
        uint64 itemId;
        uint128 goldPrice;
    }

    function placeOrders(Order[] calldata orders_) external;

    function unequipItemsAndPlaceOrders(Order[] calldata orders_, Char.CharInfo memory charInfo_) external;

    function buyOrders(Order[] calldata orders_) external;

    function buyOrdersAndEquipItems(Order[] calldata orders_, Char.CharInfo memory charInfo_) external;

    function cancelOrders(Order[] calldata orders_) external;

    function cancelOrdersAndEquipItems(Order[] calldata orders_, Char.CharInfo memory charInfo_) external;
}
