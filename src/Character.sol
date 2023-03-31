// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ERC721Votes } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICharacter } from "./interfaces/ICharacter.sol";
import { IBank } from "./interfaces/IBank.sol";
import { IItem } from "./interfaces/IItem.sol";
import { CharacterPortal } from "./CharacterPortal.sol";
import { IMilitary } from "./interfaces/IMilitary.sol";

contract Character is ICharacter, ERC721Votes, ERC721URIStorage {
    CharacterPortal public immutable portal;
    IItem public immutable item;
    IBank public immutable bank;
    address public immutable military;
    address public immutable boss;

    mapping(uint256 => CharInfo) public _charInfos;

    constructor(IBank bank_, IItem item_, address lzEndpoint_, address military_, address boss_)
        ERC721("Character", "CHAR")
        EIP712("Character", "1")
    {
        bank = bank_;
        portal = new CharacterPortal(10_000, lzEndpoint_, msg.sender);
        item = item_;
        military = military_;
        boss = boss_;
    }

    modifier onlyCharOwner(uint256 charId_) {
        _validateCharOwner(charId_);
        _;
    }

    modifier onlyPortal() {
        if (msg.sender != address(portal)) revert OnlyPortalError(msg.sender);
        _;
    }

    modifier onlyBoss() {
        if (msg.sender != boss) revert OnlyBossError(msg.sender);
        _;
    }

    function _mint(address to_, uint256 charId_, string memory tokenURI_) internal {
        super._mint(to_, charId_);
        _charInfos[charId_] = CharInfo(uint32(charId_), 1, 1, 0);
        _setTokenURI(charId_, tokenURI_);
    }

    function equipItems(uint256 charId_, uint256[] calldata itemIds_) external override onlyCharOwner(charId_) {
        uint256[] memory amounts_ = new uint256[](itemIds_.length);
        uint32 power_ = _charInfos[charId_].power;
        uint32 oldPower_ = power_;
        for (uint256 i_; i_ < itemIds_.length;) {
            amounts_[i_] = 1;
            power_ += uint32(itemIds_[i_]);
            unchecked {
                ++i_;
            }
        }
        item.burnBatch(msg.sender, itemIds_, amounts_);
        IMilitary(military).increasePower(charId_, msg.sender, oldPower_, power_ - oldPower_);
        _charInfos[charId_].power = power_;
        emit ItemsEquipped(charId_, itemIds_);
    }

    function carryGold(uint256 charId_, uint256 goldAmount_) external override onlyCharOwner(charId_) {
        bank.privilegedTransferFrom(msg.sender, address(this), goldAmount_);
        _charInfos[charId_].equippedGold += uint160(goldAmount_);
        emit GoldCarried(charId_, goldAmount_);
    }

    function dropGold(uint256 charId_, uint256 goldAmount_) external override onlyCharOwner(charId_) {
        _charInfos[charId_].equippedGold -= uint160(goldAmount_);
        bank.transfer(msg.sender, goldAmount_);
        emit GoldDropped(charId_, goldAmount_);
    }

    function sendFrom(address from_, uint16 dstChainId_, address toAddress_, uint256 charId_)
        external
        payable
        override
    {
        CharInfo memory charInfo_ = _charInfos[charId_];
        _deleteCharInfo(charId_);
        if (charInfo_.equippedGold > 0) bank.burn(address(this), uint256(charInfo_.equippedGold));
        IMilitary(military).leave(charId_, msg.sender, charInfo_.power);
        bytes[] memory data_ = new bytes[](1);
        data_[0] = abi.encode(charInfo_);
        uint256[] memory tokenId_ = new uint256[](1);
        tokenId_[0] = charId_;
        portal.send(from_, dstChainId_, toAddress_, tokenId_, payable(msg.sender), data_);
        emit CharacterSent(charInfo_, dstChainId_, toAddress_);
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
            if (charInfo_.equippedGold > 0) bank.burn(address(this), charInfo_.equippedGold);
            IMilitary(military).leave(charInfo_.charId, msg.sender, charInfo_.power);
            data_[i_] = abi.encode(charInfo_);
            emit CharacterSent(charInfo_, dstChainId_, toAddress_);
            unchecked {
                ++i_;
            }
        }
        portal.send(from_, dstChainId_, toAddress_, charIds_, payable(msg.sender), data_);
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
        if (charInfo_.equippedGold > 0) bank.mint(address(this), charInfo_.equippedGold);
        emit CharacterReceived(charInfo_, toAddress_);
    }

    function getCharInfo(uint256 charId_) external view override returns (CharInfo memory, address) {
        return (_charInfos[charId_], ownerOf(charId_));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ERC721URIStorage)
        returns (bool)
    {
        return interfaceId == type(ICharacter).interfaceId || ERC721.supportsInterface(interfaceId)
            || ERC721URIStorage.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function levelUp(uint256 charId_) external override onlyBoss {
        CharInfo memory charInfo_ = _charInfos[charId_];
        IMilitary(military).increasePower(charId_, msg.sender, charInfo_.power, 1000);
        charInfo_.level += 1;
        charInfo_.power += 1000;
        _charInfos[charId_] = charInfo_;
        emit CharacterLevelUp(charId_, charInfo_.level);
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
        override(ERC721Votes, ERC721)
    {
        ERC721Votes._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
        ERC721URIStorage._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }
}
