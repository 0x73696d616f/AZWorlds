// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { OFT } from "./dependencies/layerZero/oft/OFT.sol";
import { IGold } from "./interfaces/IGold.sol";

contract Gold is IGold, OFT {
    address immutable _character;

    error NotCharacterError(address sender);

    constructor(address character_, address lzEndpoint_) OFT("Gold", "GOLD", lzEndpoint_) {
        _character = character_;
    }

    function burn(address account_, uint256 amount_) external override {
        _validateSender();
        _burn(account_, amount_);
    }

    function mint(address account_, uint256 amount_) external override {
        _validateSender();
        _mint(account_, amount_);
    }

    function _validateSender() internal view {
        if (msg.sender != _character) revert NotCharacterError(msg.sender);
    }
}
