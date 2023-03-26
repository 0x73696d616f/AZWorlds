// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ERC721Votes } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICharacter } from "./interfaces/ICharacter.sol";
import { IBank } from "./interfaces/IBank.sol";
import { IItem } from "./interfaces/IItem.sol";

import { CharacterPortal } from "./CharacterPortal.sol";

contract Character is ICharacter, ERC721Votes {
    CharacterPortal public immutable _portal;
    IItem public immutable _item;
    IBank public immutable _bank;
    mapping(uint256 => CharInfo) public _charInfos;

    constructor(IBank bank_, IItem item_, address lzEndpoint_) ERC721("Character", "CHAR") EIP712("Character", "1") {
        _bank = bank_;
        _portal = new CharacterPortal(10_000, lzEndpoint_);
        _item = item_;
    }

    modifier onlyCharOwner(uint256 charId_) {
        _validateCharOwner(charId_);
        _;
    }

    modifier onlyPortal() {
        if (msg.sender != address(_portal)) revert OnlyPortalError(msg.sender);
        _;
    }

    function _mint(address to_, uint256 charId_) internal override {
        super._mint(to_, charId_);
        _charInfos[charId_] = CharInfo(uint32(charId_), 1, 0, 0);
    }

    function equipItems(uint256 charId_, uint256[] calldata itemIds_) external override onlyCharOwner(charId_) {
        uint256[] memory amounts_ = new uint256[](itemIds_.length);
        uint32 power_ = _charInfos[charId_].power;
        for (uint256 i_; i_ < itemIds_.length;) {
            amounts_[i_] = 1;
            power_ += uint32(itemIds_[i_]);
            unchecked {
                ++i_;
            }
        }
        _item.burnBatch(msg.sender, itemIds_, amounts_);

        _charInfos[charId_].power = power_;
    }

    function carryGold(uint256 charId_, uint256 goldAmount_) external override onlyCharOwner(charId_) {
        _bank.transferFrom(msg.sender, address(this), goldAmount_);
        _charInfos[charId_].equippedGold += uint160(goldAmount_);
    }

    function dropGold(uint256 charId_, uint256 goldAmount_) external override onlyCharOwner(charId_) {
        _charInfos[charId_].equippedGold -= uint160(goldAmount_);
        _bank.transferFrom(address(this), msg.sender, goldAmount_);
    }

    function sendFrom(address from_, uint16 dstChainId_, address toAddress_, uint256 charId_)
        external
        payable
        override
    {
        CharInfo memory charInfo_ = _charInfos[charId_];
        _deleteCharInfo(charId_);
        if (charInfo_.equippedGold > 0) _bank.burn(address(this), uint256(charInfo_.equippedGold));
        bytes[] memory data_ = new bytes[](1);
        data_[0] = abi.encode(charInfo_);
        uint256[] memory tokenId_ = new uint256[](1);
        tokenId_[0] = charId_;
        _portal.send(from_, dstChainId_, toAddress_, tokenId_, payable(msg.sender), data_);
    }

    function sendBatchFrom(address from_, uint16 dstChainId_, address toAddress_, uint256[] calldata charIds_)
        external
        payable
        override
    {
        bytes[] memory data_ = new bytes[](charIds_.length);
        CharInfo memory charInfo_;
        for (uint256 i_; i_ < charIds_.length;) {
            charInfo_ = _charInfos[charIds_[i_]];
            _deleteCharInfo(charIds_[i_]);
            if (charInfo_.equippedGold > 0) _bank.burn(address(this), charInfo_.equippedGold);
            data_[i_] = abi.encode(charInfo_);
            unchecked {
                ++i_;
            }
        }
        _portal.send(from_, dstChainId_, toAddress_, charIds_, payable(msg.sender), data_);
    }

    function creditTo(address toAddress_, uint256 tokenId_, bytes memory data_) external override onlyPortal {
        require(!_exists(tokenId_) || (_exists(tokenId_) && ERC721.ownerOf(tokenId_) == address(this)));

        if (!_exists(tokenId_)) {
            _safeMint(toAddress_, tokenId_);
        } else {
            _transfer(address(this), toAddress_, tokenId_);
        }
        (CharInfo memory charInfo_) = abi.decode(data_, (CharInfo));
        _charInfos[tokenId_] = charInfo_;
        if (charInfo_.equippedGold > 0) _bank.mint(address(this), charInfo_.equippedGold);
    }

    function getCharInfo(uint256 charId_) external view override returns (CharInfo memory, address) {
        return (_charInfos[charId_], ownerOf(charId_));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(ICharacter).interfaceId || super.supportsInterface(interfaceId);
    }

    function _validateCharOwner(uint256 charId_) internal view {
        if (ownerOf(charId_) != msg.sender) revert NotOwnerError(msg.sender);
    }

    function _deleteCharInfo(uint256 charId_) internal {
        _validateCharOwner(charId_);
        _transfer(msg.sender, address(this), charId_);
        delete _charInfos[charId_];
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Votes)
    {
        ERC721Votes._afterTokenTransfer(from, to, tokenId, batchSize);
    }
}
