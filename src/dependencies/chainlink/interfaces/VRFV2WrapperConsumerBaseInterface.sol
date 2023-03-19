// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperConsumerBaseInterface {
    function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external;
}
