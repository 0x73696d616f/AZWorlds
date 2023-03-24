// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { TimelockController } from "@openzeppelin/governance/TimelockController.sol";
import { AZWorldsGovernor } from "src/AZWorldsGovernor.sol";
import { Character } from "src/Character.sol";
import { Bank } from "src/Bank.sol";
import { Item } from "src/Item.sol";
import { Marketplace } from "src/Marketplace.sol";
import { ICharacter } from "src/interfaces/ICharacter.sol";

contract Deploy is Script {
    uint256 private _deployerPrivateKey;
    address private _deployerAddress;
    address private _layerZeroEndpoint;
    IERC20 private _asset;

    function setUp() public {
        _deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        _deployerAddress = vm.addr(_deployerPrivateKey);
        _layerZeroEndpoint = vm.addr(_deployerPrivateKey);
        _asset = IERC20(vm.addr(10));
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast(_deployerPrivateKey);

        // Deploy a new TimelockGovernor contract.
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        TimelockController timelock_ = new TimelockController(0, proposers, executors, vm.addr(_deployerPrivateKey));

        uint64 nonce_ = vm.getNonce(_deployerAddress);
        address itemAddress_ = computeCreateAddress(_deployerAddress, nonce_ + 1);
        address bankAddress_ = computeCreateAddress(_deployerAddress, nonce_ + 2);
        address marketPlaceAddress_ = computeCreateAddress(_deployerAddress, nonce_ + 3);

        Character character_ = new Character(Bank(bankAddress_), Item(itemAddress_), _layerZeroEndpoint);
        Item item_ = new Item(address(character_), marketPlaceAddress_, _layerZeroEndpoint);
        Bank bank_ = new Bank(address(character_), marketPlaceAddress_, _layerZeroEndpoint, _asset);
        Marketplace marketplace_ = new Marketplace(item_, bank_);

        uint256[] memory amounts_ = new uint256[](1);
        amounts_[0] = 1;
        uint256[] memory itemIds_ = new uint256[](1);
        itemIds_[0] = 4999;

        item_.mintBatch(_deployerAddress, itemIds_, amounts_);
        character_.mint(_deployerAddress, 1);

        ICharacter.CharInfo memory charInfo_ = ICharacter.CharInfo(1, 1, 1, 0, new bytes(625));

        character_.equipItems(charInfo_, itemIds_);

        vm.stopBroadcast();

        /*vm.startBroadcast(_deployerPrivateKey);

        AZWorldsGovernor governor_ = new AZWorldsGovernor(character_, timelock_);

        timelock_.grantRole(timelock_.PROPOSER_ROLE(), address(governor_));

        vm.stopBroadcast();*/
    }
}
