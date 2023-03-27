// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IInvestmentStrategy } from "./IInvestmentStrategy.sol";
import { IGold } from "./IGold.sol";

interface IBank is IERC4626, IGold {
    error NotGovernanceError(address sender_);

    function depositAndSendToMilitary(uint256 assets_) external;

    function invest(uint256 amount_) external;

    function withdrawInvestment(uint256 amount_) external;

    function claimRewards() external returns (uint256);

    function setInvestmentStrategy(IInvestmentStrategy strategy_) external;

    function previewRewards() external view returns (uint256);

    function getInvestment() external view returns (uint256);
}
