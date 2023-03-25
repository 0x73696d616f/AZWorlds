// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";
import { IGold } from "./IGold.sol";

interface IBank is IERC4626, IGold {
    function depositAndNotify(uint256 amount_, address to_, bytes calldata data) external;

    function invest(uint256 amount_) external;

    function withdrawInvestment(uint256 amount_) external;

    function claimRewards() external;

    function setInvestmentStrategy(address strategy_) external;

    function getRewards() external view returns (uint256);

    function getInvestment() external view returns (uint256);

    function getInvestmentStrategy() external view returns (address);
}
