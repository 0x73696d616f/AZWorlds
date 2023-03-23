// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IUSDC {
    function transferWithAuthorization(
        address from_,
        address to_,
        uint256 value_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external;

    function transfer(address to_, uint256 value_) external;
}
