// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ONFT1155 } from "./dependencies/layerZero/onft1155/ONFT1155.sol";
import { IItem } from "./interfaces/IItem.sol";

contract Item is IItem, ONFT1155 {
    address private immutable _character;
    address private immutable _marketplace;

    error NotCharacterError(address sender);

    constructor(address character_, address marketplace_, address lzEndpoint_) ONFT1155("Item", lzEndpoint_) {
        _character = character_;
        _marketplace = marketplace_;
    }

    function burn(address from, uint256 id) external override {
        _validateSender();
        _burn(from, id, 1);
    }

    function mint(address to, uint256 id) external override {
        _validateSender();
        _mint(to, id, 1, "");
    }

    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external override {
        _validateSender();
        _burnBatch(from, ids, amounts);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external override {
        _validateSender();
        _mintBatch(to, ids, amounts, "");
    }

    function marketplaceSafeTransferFrom(address from_, address to_, uint256 id_) external override {
        _validateSender();
        _safeTransferFrom(from_, to_, id_, 1, "");
    }

    function _validateSender() internal view {
        if (msg.sender != _character && msg.sender != _marketplace) revert NotCharacterError(msg.sender);
    }
}
