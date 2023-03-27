// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { OFT } from "./dependencies/layerZero/oft/OFT.sol";
import { IGold } from "./interfaces/IGold.sol";

contract Gold is OFT, IGold {
    address public immutable _character;
    address public immutable _marketplace;

    constructor(address character_, address marketPlace_, address lzEndpoint_) OFT("Gold", "GOLD", lzEndpoint_) {
        _character = character_;
        _marketplace = marketPlace_;
    }

    function privilegedTransferFrom(address from_, address to_, uint256 amount_) external override {
        _onlyCharacterOrMarketplace();
        _transfer(from_, to_, amount_);
    }

    function burn(address account_, uint256 amount_) external override {
        _burn(account_, amount_);
    }

    function mint(address account_, uint256 amount_) external override {
        _onlyCharacter();
        _mint(account_, amount_);
    }

    function _onlyCharacterOrMarketplace() internal view {
        if (msg.sender != _character && msg.sender != _marketplace) revert NotCharacterNorMarketPlaceError(msg.sender);
    }

    function _onlyCharacter() internal view {
        if (msg.sender != _character) revert NotCharacterError(msg.sender);
    }

    function _onlyMartketplace() internal view {
        if (msg.sender != _marketplace) revert NotMarketplaceError(msg.sender);
    }
}
