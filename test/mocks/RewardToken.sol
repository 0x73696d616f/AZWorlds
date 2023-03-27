// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { MockERC20 } from "./MockERC20.sol";

contract RewardToken is MockERC20 {
    constructor() MockERC20("Reward Token", "RT") { }
}
