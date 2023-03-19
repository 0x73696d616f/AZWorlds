// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";
import { TimelockController } from "@openzeppelin/governance/TimelockController.sol";
import { AZWorldsGovernor } from "src/AZWorldsGovernor.sol";
import { Character } from "src/Character.sol";

contract Deploy is Script {
    uint256 private _deployerPrivateKey;

    function setUp() public {
        _deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast(_deployerPrivateKey);

        // Deploy a new TimelockGovernor contract.
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        TimelockController timelock_ = new TimelockController(0, proposers, executors, vm.addr(_deployerPrivateKey));

        Character character_ = new Character(vm.addr(_deployerPrivateKey));

        AZWorldsGovernor governor_ = new AZWorldsGovernor(character_, timelock_);

        timelock_.grantRole(timelock_.PROPOSER_ROLE(), address(governor_));

        vm.stopBroadcast();
    }
}
