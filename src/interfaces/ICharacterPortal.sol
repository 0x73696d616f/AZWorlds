// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IONFT721Core } from "src/dependencies/layerZero/interfaces/onft721/IONFT721Core.sol";

interface ICharacterPortal is IONFT721Core {
    error NotCharacterError(address sender);

    function send(
        address from_,
        uint16 dstChainId_,
        address toAddress_,
        uint256[] memory tokenIds_,
        address payable refundAddress_,
        bytes[] memory data_
    ) external;
}
