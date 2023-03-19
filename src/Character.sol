// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ONFT721 } from "./dependencies/layerZero/onft721/ONFT721.sol";
import { ERC721Votes } from "@openzeppelin/token/ERC721/extensions/ERC721Votes.sol";
import { EIP712 } from "@openzeppelin/utils/cryptography/EIP712.sol";
import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/utils/introspection/IERC165.sol";

import { ICharacter } from "./interfaces/ICharacter.sol";
import { CharacterActionsLib } from "./library/CharacterActionsLib.sol";

contract Character is ICharacter, ONFT721, ERC721Votes {
    constructor(address lzEndpoint_) ONFT721("Character", "CHAR", 10_000, lzEndpoint_) EIP712("Character", "1") { }

    function equipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external override {
        CharacterActionsLib.equipItems(charInfo_, itemIds_);
    }

    function unequipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external override {
        CharacterActionsLib.unequipItems(charInfo_, itemIds_);
    }

    function carryGold(CharInfo memory charInfo_, uint256 gold_) external override {
        CharacterActionsLib.carryGold(charInfo_, gold_);
    }

    function dropGold(CharInfo memory charInfo_, uint256 gold_) external override {
        CharacterActionsLib.dropGold(charInfo_, gold_);
    }

    function validateCharInfo(CharInfo calldata charInfo_, uint256 charId_) external override {
        CharacterActionsLib.validateCharInfo(charInfo_, charId_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ONFT721)
        returns (bool)
    {
        return interfaceId == type(ICharacter).interfaceId || ONFT721.supportsInterface(interfaceId);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        virtual
        override(ERC721, ERC721Votes)
    {
        ERC721Votes._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}
