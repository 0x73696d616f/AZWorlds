// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ERC721Votes } from "@openzeppelin/token/ERC721/extensions/ERC721Votes.sol";
import { EIP712 } from "@openzeppelin/utils/cryptography/EIP712.sol";
import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ICharacter } from "./interfaces/ICharacter.sol";
import { IBank } from "./interfaces/IBank.sol";
import { IItem } from "./interfaces/IItem.sol";

import { CharacterPortal } from "./CharacterPortal.sol";

contract Character is ICharacter, ERC721Votes {
    CharacterPortal private immutable _portal;
    IItem private immutable _item;
    IBank internal immutable _bank;
    mapping(uint256 => bytes32) private _charInfoHashes;

    constructor(IBank bank_, IItem item_, address lzEndpoint_) ERC721("Character", "CHAR") EIP712("Character", "1") {
        _bank = bank_;
        _portal = new CharacterPortal(10_000, lzEndpoint_);
        _item = item_;
    }

    function mint(address to_, uint256 charId_) external override {
        _mint(to_, charId_);
        _charInfoHashes[charId_] = keccak256(abi.encode(CharInfo(charId_, 1, 1, 0, new bytes(625))));
    }

    function equipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external {
        _validateCharInfo(charInfo_);

        uint256[] memory amounts_ = new uint256[](itemIds_.length);
        for (uint256 i; i < itemIds_.length;) {
            amounts_[i] = 1;
            unchecked {
                ++i;
            }
        }
        _item.burnBatch(msg.sender, itemIds_, amounts_);

        for (uint256 i; i < itemIds_.length;) {
            uint256 itemId_ = itemIds_[i];
            if (itemId_ >= charInfo_.equippedItems.length * 8) _expandCharInfo(charInfo_);
            charInfo_.equippedItems[itemId_ / 8] |= bytes1(uint8(1)) << itemId_ % 8;
            unchecked {
                ++i;
            }
        }
        _charInfoHashes[charInfo_.charId] = keccak256(abi.encode(charInfo_));
    }

    function unequipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external {
        _validateCharInfo(charInfo_);
        uint256[] memory amounts_ = new uint256[](itemIds_.length);
        for (uint256 i; i < itemIds_.length;) {
            amounts_[i] = 1;
            uint256 itemId_ = itemIds_[i];
            if (itemId_ >= charInfo_.equippedItems.length * 8) _expandCharInfo(charInfo_);
            charInfo_.equippedItems[itemId_ / 8] &= ~(bytes1(uint8(1)) << itemId_ % 8);
            unchecked {
                ++i;
            }
        }
        _charInfoHashes[charInfo_.charId] = keccak256(abi.encode(charInfo_));
        _item.mintBatch(msg.sender, itemIds_, amounts_);
    }

    function carryGold(CharInfo memory charInfo_, uint256 goldAmount_) external {
        _validateCharInfo(charInfo_);
        _bank.transferFrom(msg.sender, address(this), goldAmount_);
        charInfo_.equippedGold += goldAmount_;
        _charInfoHashes[charInfo_.charId] = keccak256(abi.encode(charInfo_));
    }

    function dropGold(CharInfo memory charInfo_, uint256 goldAmount_) external {
        _validateCharInfo(charInfo_);
        charInfo_.equippedGold -= goldAmount_;
        _charInfoHashes[charInfo_.charId] = keccak256(abi.encode(charInfo_));
        _bank.transfer(msg.sender, goldAmount_);
    }

    function sendFrom(address from_, uint16 dstChainId_, address toAddress_, CharInfo calldata charInfo_)
        external
        payable
        override
    {
        _deleteCharInfo(charInfo_);
        if (charInfo_.equippedGold > 0) _bank.burn(address(this), charInfo_.equippedGold);
        bytes[] memory data_ = new bytes[](1);
        data_[0] = abi.encode(keccak256(abi.encode(charInfo_)), charInfo_.equippedGold);
        uint256[] memory tokenId_ = new uint256[](1);
        tokenId_[0] = charInfo_.charId;
        _portal.send(from_, dstChainId_, toAddress_, tokenId_, payable(msg.sender), data_);
    }

    function sendBatchFrom(address from_, uint16 dstChainId_, address toAddress_, CharInfo[] calldata charInfos_)
        external
        payable
        override
    {
        uint256[] memory tokenIds_ = new uint256[](charInfos_.length);
        bytes[] memory data_ = new bytes[](charInfos_.length);

        for (uint256 i_; i_ < charInfos_.length;) {
            tokenIds_[i_] = charInfos_[i_].charId;
            _deleteCharInfo(charInfos_[i_]);
            if (charInfos_[i_].equippedGold > 0) _bank.burn(address(this), charInfos_[i_].equippedGold);
            data_[i_] = abi.encode(keccak256(abi.encode(charInfos_[i_])), charInfos_[i_].equippedGold);
            unchecked {
                ++i_;
            }
        }
        _portal.send(from_, dstChainId_, toAddress_, tokenIds_, payable(msg.sender), data_);
    }

    function creditTo(address toAddress_, uint256 tokenId_, bytes memory data_) external {
        if (msg.sender != address(_portal)) revert OnlyPortalError(msg.sender);

        require(!_exists(tokenId_) || (_exists(tokenId_) && ERC721.ownerOf(tokenId_) == address(this)));

        if (!_exists(tokenId_)) {
            _safeMint(toAddress_, tokenId_);
        } else {
            _transfer(address(this), toAddress_, tokenId_);
        }
        (bytes32 charInfoHash_, uint256 equippedGold_) = abi.decode(data_, (bytes32, uint256));
        _charInfoHashes[tokenId_] = charInfoHash_;
        if (equippedGold_ > 0) _bank.mint(address(this), equippedGold_);
    }

    function validateCharInfo(CharInfo calldata charInfo_) public view override {
        if (ownerOf(charInfo_.charId) != msg.sender) revert NotOwnerError(msg.sender);
        if (_charInfoHashes[charInfo_.charId] != keccak256(abi.encode(charInfo_))) {
            revert InvalidCharInfoError(charInfo_);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(ICharacter).interfaceId || super.supportsInterface(interfaceId);
    }

    function _deleteCharInfo(CharInfo calldata charInfo_) internal {
        validateCharInfo(charInfo_);
        _transfer(msg.sender, address(this), charInfo_.charId);
        delete _charInfoHashes[charInfo_.charId];
    }

    function _validateCharInfo(CharInfo memory charInfo_) internal view {
        if (ownerOf(charInfo_.charId) != msg.sender) revert NotOwnerError(msg.sender);
        if (_charInfoHashes[charInfo_.charId] != keccak256(abi.encode(charInfo_))) {
            revert InvalidCharInfoError(charInfo_);
        }
    }

    function _expandCharInfo(CharInfo memory charInfo_) internal pure {
        bytes memory newItems_ = new bytes(charInfo_.equippedItems.length * 2);
        for (uint256 i; i < charInfo_.equippedItems.length;) {
            newItems_[i] = charInfo_.equippedItems[i];
            unchecked {
                ++i;
            }
        }
        charInfo_.equippedItems = newItems_;
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Votes)
    {
        ERC721Votes._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}
