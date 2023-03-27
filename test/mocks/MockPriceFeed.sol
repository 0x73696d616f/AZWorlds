// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IPriceFeed } from "src/interfaces/IPriceFeed.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockPriceFeed is IPriceFeed {
    function getRate(IERC20, IERC20, bool) external pure override returns (uint256) {
        return 27_000;
    }
}
