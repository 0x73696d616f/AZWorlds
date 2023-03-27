// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { AZWorldsGovernor } from "src/AZWorldsGovernor.sol";
import { CharacterSale } from "src/CharacterSale.sol";
import { Bank } from "src/Bank.sol";
import { Item } from "src/Item.sol";
import { Marketplace } from "src/Marketplace.sol";
import { Boss } from "src/Boss.sol";
import { Military } from "src/Military.sol";
import { MockInvestmentProtocol } from "test/mocks/MockInvestmentProtocol.sol";
import { MockInvestmentStrategy } from "test/mocks/MockInvestmentStrategy.sol";
import { MockSwapRouter } from "test/mocks/MockSwapRouter.sol";

import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Deploy is Script {
    uint256 private _deployerPrivateKey;
    address private _deployerAddress;
    address private _layerZeroEndpoint;
    MockERC20 private _usdc;
    MockERC20 private _rewardToken;
    address private _link;
    address private _vrf2Wrapper;
    uint8 private _nrChains;
    uint8 private _chainId;
    uint256 private _bossRoundDuration;
    ISwapRouter private _swapRouter;
    uint24 private _poolFee;
    uint8 private _characterFee;

    struct Addresses {
        address character;
        address item;
        address bank;
        address marketplace;
        address boss;
        address military;
    }

    function setUp() public {
        _deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        _deployerAddress = vm.addr(_deployerPrivateKey);
        _layerZeroEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
        _link = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        _vrf2Wrapper = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;
        _nrChains = 3;
        _chainId = 1;
        _bossRoundDuration = 5 minutes;
        //_swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _swapRouter = ISwapRouter(address(new MockSwapRouter())); // Sepolia has no uniswap
        _poolFee = 500;
        _usdc = MockERC20(0x1f4dA555cE2F67941D2F80231769AB1de252ce28);
        _rewardToken = MockERC20(0x67Cc0b08b6d91F8A46Bd04739DEeFc483D50B5dB);
        _characterFee = 20;
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast(_deployerPrivateKey);

        Addresses memory addresses_;
        uint64 nonce_ = vm.getNonce(_deployerAddress);
        addresses_.bank = computeCreateAddress(_deployerAddress, nonce_);
        addresses_.character = computeCreateAddress(_deployerAddress, nonce_ + 1);
        addresses_.item = computeCreateAddress(_deployerAddress, nonce_ + 2);
        addresses_.marketplace = computeCreateAddress(_deployerAddress, nonce_ + 3);
        addresses_.boss = computeCreateAddress(_deployerAddress, nonce_ + 4);
        addresses_.military = computeCreateAddress(_deployerAddress, nonce_ + 5);
        address governorAddress_ = computeCreateAddress(_deployerAddress, nonce_ + 6);

        new Bank(addresses_.character, addresses_.marketplace, addresses_.military, _layerZeroEndpoint, _usdc);
        addresses_.character = address(
            new CharacterSale(Bank(addresses_.bank ), Item(addresses_.item), addresses_.military, addresses_.boss, _layerZeroEndpoint, address(_usdc), _chainId, _nrChains, _deployerAddress, _characterFee)
        );
        new Item(addresses_.character, addresses_.marketplace, addresses_.boss, _layerZeroEndpoint);
        new Marketplace(Item(addresses_.item), Bank(addresses_.bank));
        new Boss(Item(addresses_.item), CharacterSale(addresses_.character), _link, _vrf2Wrapper, _bossRoundDuration);
        new Military(CharacterSale(addresses_.character), addresses_.bank);

        // Deploy a new TimelockGovernor contract.
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        TimelockController timelock_ = new TimelockController(10 minutes, proposers, executors, _deployerAddress);
        AZWorldsGovernor governor_ = new AZWorldsGovernor(CharacterSale(addresses_.character), timelock_);
        timelock_.grantRole(timelock_.PROPOSER_ROLE(), address(governor_));

        MockInvestmentProtocol investmentProtocol_ = new MockInvestmentProtocol(_usdc, _rewardToken);
        new MockInvestmentStrategy(Bank(addresses_.bank), investmentProtocol_, _swapRouter, _poolFee);

        vm.stopBroadcast();
    }
}
