// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IMarketplace {
    struct SellOrder {
        address seller;
        uint48 itemId;
        uint48 price;
    }

    struct BuyOrder {
        address buyer;
        uint48 itemId;
        uint48 price;
    }

    error NoOrdersError();
    error NotBuyerError(uint256 buyOrderId_);
    error NotSellerError(uint256 sellOrderId_);
    error SellOrderDoesNotExistError(uint256 sellOrderId_);
    error BuyOrderDoesNotExistError(uint256 buyOrderId_);

    function placeOrders(SellOrder[] calldata sellOrders_, BuyOrder[] calldata buyOrders_) external;

    function fullfilOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external;

    function cancelOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external;
}
