// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/token/ERC721/IERC721.sol";
import { IVotes } from "@openzeppelin/governance/utils/IVotes.sol";

interface ICharacter is IERC721, IVotes {
    struct CharInfo {
        uint256 charId;
        uint256 level;
        uint256 power;
        uint256 equippedGold;
        bytes equippedItems;
    }

    error InvalidCharInfoError(CharInfo charInfo);
    error NotOwnerError(address owner);
    error OnlyPortalError(address portal);

    function mint(address to_, uint256 charId_) external;

    function equipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external;

    function unequipItems(CharInfo memory charInfo_, uint256[] calldata itemIds_) external;

    function carryGold(CharInfo memory charInfo_, uint256 gold_) external;

    function dropGold(CharInfo memory charInfo_, uint256 gold_) external;

    function validateCharInfo(CharInfo calldata charInfo_, address owner_) external;

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address from_, uint16 dstChainId_, address toAddress_, CharInfo calldata charInfo_)
        external
        payable;

    /**
     * @dev send tokens `_tokenIds[]` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendBatchFrom(address _from, uint16 _dstChainId, address _toAddress, CharInfo[] calldata charInfos_)
        external
        payable;
}
