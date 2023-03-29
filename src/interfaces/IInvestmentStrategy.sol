// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IInvestmentStrategy {
    error NotBankError(address sender_);

    event Invested(uint256 amount_);
    event RewardsClaimed(uint256 amount_);
    event Withdraw(uint256 amount_);

    function invest(uint256 amount_) external;
    function claimRewards() external returns (uint256);
    function previewRewards() external view returns (uint256);
    function withdraw(uint256 amount_) external;
    function getTotalStaked() external view returns (uint256);
}
