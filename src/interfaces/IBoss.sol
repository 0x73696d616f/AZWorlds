// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBaseInterface } from
    "src/dependencies/chainlink/interfaces/VRFV2WrapperConsumerBaseInterface.sol";

import { ICharacter as IChar } from "./ICharacter.sol";

interface IBoss is VRFV2WrapperConsumerBaseInterface {
    error RoundNotOverError(uint256 roundId_);
    error AlreadyAttackedError(uint256 charId_, uint256 roundId_);
    error AlreadyClaimedError(uint256 charId_, uint256 roundId_);

    struct Round {
        bool attacked;
        bool claimed;
    }

    event RoundStarted(uint256 indexed roundId, uint256 timestamp);
    event BossAttacked(uint256 indexed roundId, uint256 indexed charId);
    event RewardClaimed(uint256 indexed roundId, uint256 indexed charId, uint256 itemId);
    event RandomWordsFulfilled(uint256 indexed roundId, uint256 seed);

    error NotCharOwnerError(uint256 charId_, address sender_);

    function attackBoss(uint256 charId_) external;

    function claimRewards(uint256 charId_, uint256 roundId_) external returns (uint256 itemId_);

    function previewRewards(uint256 charId_, uint256 roundId_) external view returns (uint256 itemId_);

    function nextRound() external;
}
