// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";

contract Deploy is Script {
    address private _deployerAddress;
    uint256 private _deployerPrivateKey;
    MockERC20 private _usdc;
    MockERC20 private _rewardToken;

    function setUp() public {
        _deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        _deployerAddress = vm.addr(_deployerPrivateKey);
    }

    function run() public {
        vm.startBroadcast(_deployerPrivateKey);

        _usdc = new MockERC20("Mock USD Coin", "MUSDC");
        _rewardToken = new MockERC20("Mock Reward Token", "MRT");
        _usdc.mint(_deployerAddress, 1_000_000_000e18);
        _rewardToken.mint(_deployerAddress, 1_000_000_000e18);

        vm.stopBroadcast();
    }
}
