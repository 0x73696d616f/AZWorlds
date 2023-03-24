// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { OFT } from "./dependencies/layerZero/oft/OFT.sol";
import { IGold } from "./interfaces/IGold.sol";

contract Gold is OFT, IGold {
    address immutable _character;
    address immutable _marketplace;

    error NotCharacterError(address sender);
    error NotMarketplaceError(address sender);

    constructor(address character_, address marketPlace_, address lzEndpoint_) OFT("Gold", "GOLD", lzEndpoint_) {
        _character = character_;
        _marketplace = marketPlace_;
    }

    function marketplaceTransferFrom(address from_, address to_, uint256 amount_) external override {
        _onlyMartketplace();
        _transfer(from_, to_, amount_);
    }

    function burn(address account_, uint256 amount_) external override {
        _onlyCharacter();
        _burn(account_, amount_);
    }

    function mint(address account_, uint256 amount_) external override {
        _onlyCharacter();
        _mint(account_, amount_);
    }

    function _onlyCharacter() internal view {
        if (msg.sender != _character) revert NotCharacterError(msg.sender);
    }

    function _onlyMartketplace() internal view {
        if (msg.sender != _marketplace) revert NotMarketplaceError(msg.sender);
    }
}
