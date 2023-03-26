// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as IChar } from "./ICharacter.sol";

interface IMilitary {
    struct Deposit {
        uint192 amount;
        uint64 expireTimestamp;
    }

    struct CharInfo {
        uint224 goldPerPower;
        uint32 power;
    }

    error NotBankError(address msgSender_);
    error NotCharacterError(address msgSender_);
    error NotCharOwnerError(uint256 charId_, address msgSender_);
    error NotEnlistedError(uint256 charId_);
    error ZeroPowerChangeError(uint256 charId_);

    function deposit(uint256 amount_) external;

    function join(uint256 charId_) external;

    function leave(uint256 charId_) external;

    function leave(uint256 charId_, address owner_, uint256 charPower_) external;

    function modifyPower(uint256 charId_, address owner_, uint256 oldPower_, int256 powerChange_) external;

    function getRewards(uint256 charId_) external;

    function previewRewards(uint256 charId_) external view returns (uint256);

    function isCharEnlisted(uint256 charId_) external view returns (bool);
}
