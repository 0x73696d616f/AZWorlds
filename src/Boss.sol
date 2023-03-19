// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBase } from "src/dependencies/chainlink/VRFV2WrapperConsumerBase.sol";
import { IBoss } from "./interfaces/IBoss.sol";
import { ICharacter as Char } from "./interfaces/ICharacter.sol";

contract Boss is IBoss, VRFV2WrapperConsumerBase {
    constructor(address link_, address vrfV2Wrapper_) VRFV2WrapperConsumerBase(link_, vrfV2Wrapper_) { }

    function attackBoss(Char.CharInfo calldata charInfo_) external override { }

    function claimRewards(uint256 charId_) external override { }

    function claimRewardsAndEquipItems(Char.CharInfo memory charInfo_, uint256[] calldata itemIds_) external override { }

    function previewRewards(uint256 charId_) external view override returns (uint256[] memory itemIds_) { }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override { }
}
