// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { OFT } from "./dependencies/layerZero/oft/OFT.sol";
import { IGold } from "./interfaces/IGold.sol";

contract Gold is OFT {
    constructor(address lzEndpoint_) OFT("Gold", "GOLD", lzEndpoint_) { }
}
