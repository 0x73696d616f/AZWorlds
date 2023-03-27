// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";

interface ICharacter is IERC721, IVotes {
    struct CharInfo {
        uint32 charId;
        uint32 level;
        uint32 power;
        uint160 equippedGold;
    }

    error InvalidCharInfoError(CharInfo charInfo);
    error NotOwnerError(address owner);
    error OnlyPortalError(address portal);
    error OnlyBossError(address boss);

    function equipItems(uint256 charId_, uint256[] calldata itemIds_) external;

    function carryGold(uint256 charId_, uint256 goldAmount_) external;

    function dropGold(uint256 charId_, uint256 goldAmount_) external;

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(address from_, uint16 dstChainId_, address toAddress_, uint256 charId_) external payable;

    /**
     * @dev send tokens `_tokenIds[]` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendBatchFrom(address _from, uint16 _dstChainId, address _toAddress, uint256[] calldata charIds_)
        external
        payable;

    function creditTo(address toAddress_, uint256 tokenId_, bytes memory data_) external;

    function levelUp(uint256 charId_) external;

    function getCharInfo(uint256 charId_) external view returns (CharInfo memory, address);
}
