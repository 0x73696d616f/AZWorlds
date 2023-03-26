// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { MockERC20 } from "./MockERC20.sol";

contract MockInvestmentProtocol {
    mapping(address => uint256) public totalStaked;
    MockERC20 public rewardToken;
    MockERC20 public stakedToken;
    mapping(address => uint256) public lastRewardClaimed;
    uint256 public APY = 5;

    constructor(MockERC20 stakedToken_, MockERC20 rewardToken_) {
        rewardToken = rewardToken_;
        stakedToken = stakedToken_;
    }

    function stake(uint256 amount_) external returns (uint256 rewards_) {
        rewards_ = claimRewards();
        stakedToken.transferFrom(msg.sender, address(this), amount_);
        totalStaked[msg.sender] += amount_;
    }

    function claimRewards() public returns (uint256 rewards_) {
        rewards_ = previewRewards();
        MockERC20(rewardToken).mint(msg.sender, rewards_);
        lastRewardClaimed[msg.sender] = block.timestamp;
    }

    function previewRewards() public view returns (uint256) {
        return totalStaked[msg.sender] * (block.timestamp - lastRewardClaimed[msg.sender]) * 5 / 100 / 365;
    }

    function withdraw(uint256 amount_) external returns (uint256 rewards_) {
        rewards_ = claimRewards();
        totalStaked[msg.sender] -= amount_;
        stakedToken.transfer(msg.sender, amount_);
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked[msg.sender];
    }
}
