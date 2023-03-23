// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ONFT1155 } from "./dependencies/layerZero/onft1155/ONFT1155.sol";
import { IItem } from "./interfaces/IItem.sol";

contract Item is IItem, ONFT1155 {
    address private immutable _character;

    error NotCharacterError(address sender);

    constructor(address character_, address lzEndpoint_) ONFT1155("Item", lzEndpoint_) {
        _character = character_;
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external override {
        //_validateSender();
        _burnBatch(from, ids, amounts);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external override {
        //_validateSender();
        _mintBatch(to, ids, amounts, "");
    }

    function _validateSender() internal view {
        if (msg.sender != _character) revert NotCharacterError(msg.sender);
    }
}
