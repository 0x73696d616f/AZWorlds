// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { OFT } from "./dependencies/layerZero/oft/OFT.sol";
import { IGold } from "./interfaces/IGold.sol";

contract Gold is OFT, IGold {
    address public immutable character;
    address public immutable marketplace;
    address public immutable game;

    constructor(address character_, address marketPlace_, address lzEndpoint_, address game_)
        OFT("Gold", "GOLD", lzEndpoint_)
    {
        character = character_;
        marketplace = marketPlace_;
        game = game_;
    }

    function privilegedTransferFrom(address from_, address to_, uint256 amount_) external override {
        _validateSender();
        _transfer(from_, to_, amount_);
    }

    function burn(address account_, uint256 amount_) external override {
        _burn(account_, amount_);
    }

    function mint(address account_, uint256 amount_) external override {
        _onlyCharacter();
        _mint(account_, amount_);
    }

    function _validateSender() internal view {
        if (msg.sender != character && msg.sender != marketplace && msg.sender != game) {
            revert NotPrivilegedSender(msg.sender);
        }
    }

    function _onlyCharacter() internal view {
        if (msg.sender != character) revert NotCharacterError(msg.sender);
    }
}
