// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IMarketplace } from "./interfaces/IMarketplace.sol";
import { IItem } from "./interfaces/IItem.sol";
import { IGold } from "./interfaces/IGold.sol";

contract Marketplace is IMarketplace {
    BuyOrder[] private _buyOrders;
    SellOrder[] private _sellOrders;

    IItem private immutable _item;
    IGold private immutable _gold;

    constructor(IItem item_, IGold gold_) {
        _item = item_;
        _gold = gold_;
    }

    function placeOrders(uint256[] calldata sellOrdersIds_, uint80[] calldata sellOrderPrices_, uint16[] calldata buyOrdersIds_, uint80[] calldata buyOrderPrices_) external override {
        if (sellOrdersIds_.length == 0 && buyOrdersIds_.length == 0) revert NoOrdersError();
        require(sellOrdersIds_.length == sellOrderPrices_.length, "Marketplace: sellOrdersIds_.length != sellOrderPrices_.length");
        require(buyOrdersIds_.length == buyOrderPrices_.length, "Marketplace: buyOrdersIds_.length != buyOrderPrices_.length");

        uint256 totalGoldInBuyOrders_;
        for (uint256 i_; i_ < buyOrdersIds_.length;) {
            totalGoldInBuyOrders_ += buyOrderPrices_[i_];
            _buyOrders.push(BuyOrder(msg.sender, buyOrdersIds_[i_], buyOrderPrices_[i_]));
            emit BuyOrderPlaced(msg.sender, buyOrdersIds_[i_], buyOrderPrices_[i_]);
            unchecked {
                ++i_;
            }
        }
        if (totalGoldInBuyOrders_ != 0) _gold.privilegedTransferFrom(msg.sender, address(this), totalGoldInBuyOrders_);

        uint256[] memory amounts_ = new uint256[](sellOrdersIds_.length);
        for (uint256 i_; i_ < sellOrdersIds_.length;) {
            amounts_[i_] = 1;
            _sellOrders.push(SellOrder(msg.sender, uint16(sellOrdersIds_[i_]), sellOrderPrices_[i_]));
            emit SellOrderPlaced(msg.sender, uint16(sellOrdersIds_[i_]), sellOrderPrices_[i_]);
            unchecked {
                ++i_;
            }
        }
        if (sellOrdersIds_.length != 0) _item.burnBatch(msg.sender, sellOrdersIds_, amounts_);
    }

    function fulfilOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external override {
        if (sellOrderIds_.length == 0 && buyOrderIds_.length == 0) revert NoOrdersError();

        for (uint256 i_; i_ < sellOrderIds_.length;) {
            SellOrder memory sellOrder_ = _sellOrders[sellOrderIds_[i_]];
            if (sellOrder_.seller == address(0)) revert SellOrderDoesNotExistError(sellOrderIds_[i_]);
            delete _sellOrders[sellOrderIds_[i_]];
            _gold.privilegedTransferFrom(msg.sender, sellOrder_.seller, sellOrder_.price);
            _item.mint(msg.sender, sellOrder_.itemId);
            emit SellOrderFulfilled(sellOrder_.seller, sellOrder_.itemId, sellOrder_.price);
            unchecked {
                ++i_;
            }
        }

        uint256 totalGoldInBuyOrders_;
        for (uint256 i_; i_ < buyOrderIds_.length;) {
            BuyOrder memory buyOrder_ = _buyOrders[buyOrderIds_[i_]];
            if (buyOrder_.buyer == address(0)) revert BuyOrderDoesNotExistError(buyOrderIds_[i_]);
            delete _buyOrders[buyOrderIds_[i_]];
            totalGoldInBuyOrders_ += buyOrder_.price;
            _item.privilegedSafeTransferFrom(msg.sender, buyOrder_.buyer, buyOrder_.itemId);
            emit BuyOrderFulfilled(buyOrder_.buyer, buyOrder_.itemId, buyOrder_.price);
            unchecked {
                ++i_;
            }
        }
        _gold.transfer(msg.sender, totalGoldInBuyOrders_);
    }

    function cancelOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external override {
        if (sellOrderIds_.length == 0 && buyOrderIds_.length == 0) revert NoOrdersError();

        for (uint256 i_; i_ < sellOrderIds_.length;) {
            SellOrder memory sellOrder_ = _sellOrders[sellOrderIds_[i_]];
            if (sellOrder_.seller == address(0)) revert SellOrderDoesNotExistError(sellOrderIds_[i_]);
            if (sellOrder_.seller != msg.sender) revert NotSellerError(sellOrderIds_[i_]);
            delete _sellOrders[sellOrderIds_[i_]];
            _item.mint(msg.sender, sellOrder_.itemId);
            emit SellOrderCancelled(sellOrder_.seller, sellOrder_.itemId, sellOrder_.price);
            unchecked {
                ++i_;
            }
        }

        uint256 totalGoldInBuyOrders_;
        for (uint256 i_; i_ < buyOrderIds_.length;) {
            BuyOrder memory buyOrder_ = _buyOrders[buyOrderIds_[i_]];
            if (buyOrder_.buyer == address(0)) revert BuyOrderDoesNotExistError(buyOrderIds_[i_]);
            if (buyOrder_.buyer != msg.sender) revert NotBuyerError(buyOrderIds_[i_]);
            delete _buyOrders[buyOrderIds_[i_]];
            totalGoldInBuyOrders_ += buyOrder_.price;
            emit BuyOrderCancelled(buyOrder_.buyer, buyOrder_.itemId, buyOrder_.price);
            unchecked {
                ++i_;
            }
        }
        _gold.transfer(msg.sender, totalGoldInBuyOrders_);
    }

    function getBuyOrders() external view override returns (BuyOrder[] memory) {
        return _buyOrders;
    }

    function getSellOrders() external view override returns (SellOrder[] memory) {
        return _sellOrders;
    }
}
