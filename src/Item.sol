// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ONFT1155 } from "./dependencies/layerZero/onft1155/ONFT1155.sol";
import { IItem } from "./interfaces/IItem.sol";

contract Item is ONFT1155 {
    constructor(address lzEndpoint_) ONFT1155("Some uri", lzEndpoint_) { }
}
