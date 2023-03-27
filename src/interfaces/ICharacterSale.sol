// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter } from "./ICharacter.sol";

interface ICharacterSale is ICharacter {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function buy(
        address from_,
        uint256 usdcSent_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        Signature calldata
    ) external returns (uint256 mintedId);

    function getPrice() external view returns (uint256 price_);
}
