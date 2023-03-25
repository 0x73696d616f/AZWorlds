// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { VRFV2WrapperConsumerBase } from "src/dependencies/chainlink/VRFV2WrapperConsumerBase.sol";
import { Babylonian } from "src/dependencies/Babylonian.sol";
import { IItem } from "./interfaces/IItem.sol";
import { ICharacter as IChar } from "./interfaces/ICharacter.sol";
import { IBoss } from "./interfaces/IBoss.sol";

contract Boss is IBoss, VRFV2WrapperConsumerBase {
    uint256 public constant ROUND_DURATION = 1 days;
    uint256 public constant MAX_ITEM_ID = 4999;
    uint256 public immutable MAX_NUMBER_SQRT;

    mapping(uint256 => mapping(uint256 => Round)) public charInfo;
    mapping(uint256 => uint256) public roundSeed;
    uint256 public lastRoundTimestamp = block.timestamp;
    uint256 public roundId;
    IItem public _item;
    IChar public _char;

    constructor(IItem item_, IChar char_, address link_, address vrfV2Wrapper_)
        VRFV2WrapperConsumerBase(link_, vrfV2Wrapper_)
    {
        _item = item_;
        _char = char_;
        MAX_NUMBER_SQRT = Babylonian.sqrt(type(uint256).max);
    }

    function attackBoss(uint256 charId_) external override {
        nextRound();
        if (_char.ownerOf(charId_) != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
        charInfo[roundId][charId_].attacked = true;
    }

    function claimRewards(uint256 charId_, uint256 roundId_) external override {
        nextRound();
        if (_char.ownerOf(charId_) != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
        if (charInfo[roundId_][charId_].attacked && !charInfo[roundId_][charId_].claimed) {
            uint256 itemId_ = MAX_ITEM_ID
                - MAX_ITEM_ID * Babylonian.sqrt(uint256(keccak256(abi.encodePacked(roundSeed[roundId_], charId_))))
                    / MAX_NUMBER_SQRT;
            _item.mint(msg.sender, itemId_);
            charInfo[roundId_][charId_].claimed = true;
        }
    }

    function previewRewards(uint256 charId_, uint256 roundId_) external view override returns (uint256 itemId_) {
        itemId_ = MAX_ITEM_ID
            - MAX_ITEM_ID * Babylonian.sqrt(uint256(keccak256(abi.encodePacked(roundSeed[roundId_], charId_))))
                / MAX_NUMBER_SQRT;
    }

    function nextRound() public override {
        if (block.timestamp - lastRoundTimestamp < ROUND_DURATION) return;
        lastRoundTimestamp = block.timestamp;
        requestRandomness(60_000, 10, 1);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        roundSeed[roundId++] = _randomWords[0];
    }
}
