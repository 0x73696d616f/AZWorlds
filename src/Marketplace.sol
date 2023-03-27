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

    function placeOrders(SellOrder[] memory sellOrders_, BuyOrder[] memory buyOrders_) external override {
        if (sellOrders_.length == 0 && buyOrders_.length == 0) revert NoOrdersError();

        uint256 totalGoldInBuyOrders_;
        for (uint256 i_; i_ < buyOrders_.length;) {
            buyOrders_[i_].buyer = msg.sender;
            totalGoldInBuyOrders_ += buyOrders_[i_].price;
            _buyOrders.push(buyOrders_[i_]);
            unchecked {
                ++i_;
            }
        }
        if (totalGoldInBuyOrders_ != 0) _gold.privilegedTransferFrom(msg.sender, address(this), totalGoldInBuyOrders_);

        uint256[] memory itemIds_ = new uint256[](sellOrders_.length);
        uint256[] memory amounts_ = new uint256[](sellOrders_.length);
        for (uint256 i_; i_ < sellOrders_.length;) {
            sellOrders_[i_].seller = msg.sender;
            itemIds_[i_] = sellOrders_[i_].itemId;
            amounts_[i_] = 1;
            _sellOrders.push(sellOrders_[i_]);
            unchecked {
                ++i_;
            }
        }
        if (itemIds_.length != 0) _item.burnBatch(msg.sender, itemIds_, amounts_);
    }

    function fullfilOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external override {
        if (sellOrderIds_.length == 0 && buyOrderIds_.length == 0) revert NoOrdersError();

        for (uint256 i_; i_ < sellOrderIds_.length;) {
            SellOrder memory sellOrder_ = _sellOrders[sellOrderIds_[i_]];
            if (sellOrder_.seller == address(0)) revert SellOrderDoesNotExistError(sellOrderIds_[i_]);
            delete _sellOrders[sellOrderIds_[i_]];
            _gold.privilegedTransferFrom(msg.sender, sellOrder_.seller, sellOrder_.price);
            _item.mint(msg.sender, sellOrder_.itemId);
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
            _item.marketplaceSafeTransferFrom(msg.sender, buyOrder_.buyer, buyOrder_.itemId);
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
