// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBaseInterface } from
    "src/dependencies/chainlink/interfaces/VRFV2WrapperConsumerBaseInterface.sol";

import { ICharacter as IChar } from "./ICharacter.sol";

interface IBoss is VRFV2WrapperConsumerBaseInterface {
    struct Round {
        bool attacked;
        bool claimed;
    }

    error NotCharOwnerError(uint256 charId_, address sender_);

    function attackBoss(uint256 charId_) external;

    function claimRewards(uint256 charId_, uint256 roundId_) external;

    function previewRewards(uint256 charId_, uint256 roundId_) external view returns (uint256 itemId_);

    function nextRound() external;
}
