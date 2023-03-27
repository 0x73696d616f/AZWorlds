// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ONFT721Core } from "./dependencies/layerZero/onft721/ONFT721Core.sol";
import { Character } from "./Character.sol";
import { ICharacterPortal } from "./interfaces/ICharacterPortal.sol";

contract CharacterPortal is ICharacterPortal, ONFT721Core {
    Character public immutable _character;

    constructor(uint256 _minGasToTransferAndStore, address _lzEndpoint, address owner_)
        ONFT721Core(_minGasToTransferAndStore, _lzEndpoint)
    {
        _character = Character(msg.sender);
        transferOwnership(owner_);
    }

    function send(
        address from_,
        uint16 dstChainId_,
        address toAddress_,
        uint256[] memory tokenIds_,
        address payable refundAddress_,
        bytes[] memory data_
    ) external {
        if (msg.sender != address(_character)) revert NotCharacterError(msg.sender);
        _send(from_, dstChainId_, abi.encode(toAddress_), tokenIds_, refundAddress_, address(0), "", data_);
    }

    function _creditTo(uint16, address _toAddress, uint256 _tokenId, bytes memory _data) internal virtual override {
        _character.creditTo(_toAddress, _tokenId, _data);
    }
}
