// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IMarketplace {
    struct SellOrder {
        address seller;
        uint16 itemId;
        uint80 price;
    }

    struct BuyOrder {
        address buyer;
        uint16 itemId;
        uint80 price;
    }

    event SellOrderPlaced(address indexed seller, uint16 itemId, uint80 price);
    event BuyOrderPlaced(address indexed buyer, uint16 itemId, uint80 price);
    event SellOrderCancelled(address indexed seller, uint16 itemId, uint80 price);
    event BuyOrderCancelled(address indexed buyer, uint16 itemId, uint80 price);
    event SellOrderFulfilled(address indexed seller, uint16 itemId, uint80 price);
    event BuyOrderFulfilled(address indexed buyer, uint16 itemId, uint80 price);

    error NoOrdersError();
    error NotBuyerError(uint256 buyOrderId_);
    error NotSellerError(uint256 sellOrderId_);
    error SellOrderDoesNotExistError(uint256 sellOrderId_);
    error BuyOrderDoesNotExistError(uint256 buyOrderId_);

    function placeOrders(
        uint256[] calldata sellOrdersIds_,
        uint80[] calldata sellOrderPrices_,
        uint16[] calldata buyOrdersIds_,
        uint80[] calldata buyOrderPrices
    ) external;

    function fulfilOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external;

    function cancelOrders(uint256[] calldata sellOrderIds_, uint256[] calldata buyOrderIds_) external;

    function getBuyOrders() external view returns (BuyOrder[] memory);

    function getSellOrders() external view returns (SellOrder[] memory);
}
