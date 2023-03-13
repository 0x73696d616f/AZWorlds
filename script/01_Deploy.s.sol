// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";

contract Deploy is Script {
    function setUp() public {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
}
