// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICharacter } from "../src/interfaces/ICharacter.sol";
import { Fixture } from "./Fixture.t.sol";
import { IItem } from "src/interfaces/IItem.sol";
import { Bank } from "src/Bank.sol";
import { IMarketplace } from "src/interfaces/IMarketplace.sol";

contract MarketplaceTest is Fixture {
    function setUp() public virtual override {
        super.setUp();
    }

    function testPlaceAndFulfillOrders() public {
        address player2_ = vm.addr(3);
        vm.label(player2_, "player2");

        uint256 player1Gold_ = 100;
        uint256 player1ItemId_ = 0;
        _mintGold(_player1, player1Gold_);
        _mintItem(_player1, player1ItemId_);

        uint256 player2Gold_ = 200;
        uint256 player2ItemId_ = 1;
        _mintGold(player2_, player2Gold_);
        _mintItem(player2_, player2ItemId_);

        uint256 sellOrderPrice_ = 20;
        uint256 buyOrderPrice_ = 10;

        uint256[] memory sellOrderItemIds_ = new uint256[](1);
        sellOrderItemIds_[0] = player1ItemId_;
        uint16[] memory buyOrderItemIds_ = new uint16[](1);
        buyOrderItemIds_[0] = uint16(player2ItemId_);
        uint80[] memory sellOrderPrices_ = new uint80[](1);
        sellOrderPrices_[0] = uint80(sellOrderPrice_);
        uint80[] memory buyOrderPrices_ = new uint80[](1);
        buyOrderPrices_[0] = uint80(buyOrderPrice_);

        vm.prank(_player1);
        IMarketplace(_marketplace).placeOrders(sellOrderItemIds_, sellOrderPrices_, buyOrderItemIds_, buyOrderPrices_);
        assertEq(IMarketplace(_marketplace).getSellOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getBuyOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].seller, _player1);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].itemId, player1ItemId_);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].price, sellOrderPrice_);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].buyer, _player1);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].itemId, player1ItemId_ + 1);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].price, buyOrderPrice_);

        uint256[] memory buyOrderIds_ = new uint256[](1);
        buyOrderIds_[0] = 0;
        uint256[] memory sellOrderIds_ = new uint256[](1);
        sellOrderIds_[0] = 0;
        vm.prank(player2_);
        IMarketplace(_marketplace).fulfilOrders(sellOrderIds_, buyOrderIds_);
        assertEq(IMarketplace(_marketplace).getSellOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getBuyOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].seller, address(0));
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].itemId, 0);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].price, 0);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].buyer, address(0));
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].itemId, 0);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].price, 0);

        assertEq(IItem(_item).balanceOf(_player1, player1ItemId_), 0);
        assertEq(IItem(_item).balanceOf(_player1, player2ItemId_), 1);
        assertEq(IItem(_item).balanceOf(player2_, player1ItemId_), 1);
        assertEq(IItem(_item).balanceOf(player2_, player2ItemId_), 0);
        assertEq(Bank(_bank).balanceOf(_player1), player1Gold_ - buyOrderPrice_ + sellOrderPrice_);
        assertEq(Bank(_bank).balanceOf(player2_), player2Gold_ - sellOrderPrice_ + buyOrderPrice_);
    }

    function testCancelOrders() public {
        address player2_ = vm.addr(3);
        vm.label(player2_, "player2");

        uint256 player1Gold_ = 100;
        uint256 player1ItemId_ = 0;
        _mintGold(_player1, player1Gold_);
        _mintItem(_player1, player1ItemId_);

        uint256 player2Gold_ = 200;
        uint256 player2ItemId_ = 1;
        _mintGold(player2_, player2Gold_);
        _mintItem(player2_, player2ItemId_);

        uint256 sellOrderPrice_ = 20;
        uint256 buyOrderPrice_ = 10;

        uint256[] memory sellOrderItemIds_ = new uint256[](1);
        sellOrderItemIds_[0] = player1ItemId_;
        uint16[] memory buyOrderItemIds_ = new uint16[](1);
        buyOrderItemIds_[0] = uint16(player2ItemId_);
        uint80[] memory sellOrderPrices_ = new uint80[](1);
        sellOrderPrices_[0] = uint80(sellOrderPrice_);
        uint80[] memory buyOrderPrices_ = new uint80[](1);
        buyOrderPrices_[0] = uint80(buyOrderPrice_);

        vm.prank(_player1);
        IMarketplace(_marketplace).placeOrders(sellOrderItemIds_, sellOrderPrices_, buyOrderItemIds_, buyOrderPrices_);
        assertEq(IMarketplace(_marketplace).getSellOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getBuyOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].seller, _player1);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].itemId, player1ItemId_);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].price, sellOrderPrice_);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].buyer, _player1);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].itemId, player1ItemId_ + 1);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].price, buyOrderPrice_);

        uint256[] memory buyOrderIds_ = new uint256[](1);
        buyOrderIds_[0] = 0;
        uint256[] memory sellOrderIds_ = new uint256[](1);
        sellOrderIds_[0] = 0;
        vm.prank(_player1);
        IMarketplace(_marketplace).cancelOrders(sellOrderIds_, buyOrderIds_);
        assertEq(IMarketplace(_marketplace).getSellOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getBuyOrders().length, 1);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].seller, address(0));
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].itemId, 0);
        assertEq(IMarketplace(_marketplace).getSellOrders()[0].price, 0);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].buyer, address(0));
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].itemId, 0);
        assertEq(IMarketplace(_marketplace).getBuyOrders()[0].price, 0);
    }
}
