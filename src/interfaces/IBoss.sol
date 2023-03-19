// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBaseInterface } from
    "src/dependencies/chainlink/interfaces/VRFV2WrapperConsumerBaseInterface.sol";

import { ICharacter as Char } from "./ICharacter.sol";

interface IBoss is VRFV2WrapperConsumerBaseInterface {
    function attackBoss(Char.CharInfo calldata charInfo_) external;

    function claimRewards(uint256 charId_) external;

    function claimRewardsAndEquipItems(Char.CharInfo memory charInfo_, uint256[] calldata itemIds_) external;

    function previewRewards(uint256 charId_) external view returns (uint256[] memory itemIds_);
}
