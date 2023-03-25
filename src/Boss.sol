// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBase } from "src/dependencies/chainlink/VRFV2WrapperConsumerBase.sol";
import { IBoss } from "./interfaces/IBoss.sol";

contract Boss is IBoss, VRFV2WrapperConsumerBase {
    constructor(address link_, address vrfV2Wrapper_) VRFV2WrapperConsumerBase(link_, vrfV2Wrapper_) { }

    function attackBoss(uint256 charId_) external override { }

    function claimRewards(uint256 charId_) external override { }

    function previewRewards(uint256 charId_) external view override returns (uint256[] memory itemIds_) { }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override { }
}
