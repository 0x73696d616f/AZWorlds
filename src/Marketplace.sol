// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IMarketplace } from "./interfaces/IMarketplace.sol";
import { ICharacter as Char } from "./interfaces/ICharacter.sol";

contract Marketplace is IMarketplace {
    function placeOrders(Order[] calldata orders_) external override { }

    function unequipItemsAndPlaceOrders(Order[] calldata orders_, Char.CharInfo memory charInfo_) external override { }

    function buyOrders(Order[] calldata orders_) external override { }

    function buyOrdersAndEquipItems(Order[] calldata orders_, Char.CharInfo memory charInfo_) external override { }

    function cancelOrders(Order[] calldata orders_) external override { }

    function cancelOrdersAndEquipItems(Order[] calldata orders_, Char.CharInfo memory charInfo_) external override { }
}
