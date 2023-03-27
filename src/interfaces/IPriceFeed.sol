// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeed {
    function getRate(IERC20 srcToken_, IERC20 dstToken_, bool useWrappers_) external view returns (uint256 rate_);
}
