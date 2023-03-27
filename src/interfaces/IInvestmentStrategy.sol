// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IInvestmentStrategy {
    error NotBankError(address sender_);

    function invest(uint256 amount_) external;
    function claimRewards() external returns (uint256);
    function previewRewards() external view returns (uint256);
    function withdraw(uint256 amount_) external;
    function getTotalStaked() external view returns (uint256);
}
