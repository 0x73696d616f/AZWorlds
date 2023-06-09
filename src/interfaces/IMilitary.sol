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

    event Deposited(uint256 amount_, uint256 expireTimestamp_);
    event Joined(uint256 indexed charId_, uint256 power_);
    event Left(uint256 indexed charId_, uint256 rewards_);
    event PowerIncreased(uint256 indexed charId_, uint256 powerChange_);
    event TotalPowerUpdated(uint256 totalPower_);
    event FirstExpiringDepositUpdated(uint256 index);
    event GoldPerPowerofCharUpdated(uint256 indexed charId_, uint256 goldPerPower_);
    event GoldPerPowerUpdated(uint256 goldPerPower_);
    event GoldBurned(uint256 amount_);
    event TotalDepositedUpdated(uint256 totalDeposited_);
    event RewardsClaimed(uint256 indexed charId_, uint256 rewards_);

    error NotBankError(address msgSender_);
    error NotCharacterError(address msgSender_);
    error NotCharOwnerError(uint256 charId_, address msgSender_);
    error AlreadyEnlistedError(uint256 charId_);

    function deposit(uint256 amount_) external;

    function join(uint256 charId_) external;

    function leave(uint256 charId_) external returns (uint256 rewards_);

    function leave(uint256 charId_, address owner_, uint256 charPower_) external;

    function increasePower(uint256 charId_, address owner_, uint256 oldPower_, uint256 powerChange_) external;

    function getRewards(uint256 charId_) external returns (uint256 rewards_);

    function previewRewards(uint256 charId_) external view returns (uint256);

    function isCharEnlisted(uint256 charId_) external view returns (bool);
}
