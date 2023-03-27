// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "@forge-std/Test.sol";
import { console } from "@forge-std/console.sol";
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

contract Fixture is Test {
    struct Addresses {
        address character;
        address item;
        address bank;
        address marketplace;
        address boss;
        address military;
        address investmentProtocol;
        address investmentStrategy;
        address governor;
    }

    struct AddressesExternal {
        address layerZeroEndpoint;
        address link;
        address vrf2Wrapper;
        address swapRouter;
        address usdc;
        address rewardToken;
    }

    struct Constants {
        uint8 nrChains;
        uint8 chainId;
        uint256 bossRoundDuration;
        uint24 poolFee;
    }

    address internal _deployer = vm.addr(1);
    uint256 internal _player1PK = 2;
    address internal _player1 = vm.addr(_player1PK);
    uint256 internal _player1CharId = 1;
    mapping(address => uint256) _nonces;
    Addresses internal _addrs;
    AddressesExternal internal _addrsExt;
    Constants internal _cts;

    function setUp() public virtual {
        vm.deal(_deployer, 10 ether);
        vm.deal(_player1, 10 ether);
        vm.label(_deployer, "deployer");
        vm.label(_player1, "player1");
        vm.startPrank(_deployer);
        _addrsExt.layerZeroEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
        _addrsExt.link = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        _addrsExt.vrf2Wrapper = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;
        _cts.nrChains = 3;
        _cts.chainId = 1;
        _cts.bossRoundDuration = 5 minutes;
        _addrsExt.swapRouter = address(new MockSwapRouter());
        _cts.poolFee = 500;
        _addrsExt.usdc = address(new MockERC20("Mock USD Coin", "USDC"));
        _addrsExt.rewardToken = address(new MockERC20("Mock Reward Token", "MRT"));

        uint64 nonce_ = vm.getNonce(_deployer);
        _addrs.bank = computeCreateAddress(_deployer, nonce_);
        _addrs.character = computeCreateAddress(_deployer, nonce_ + 1);
        _addrs.item = computeCreateAddress(_deployer, nonce_ + 2);
        _addrs.marketplace = computeCreateAddress(_deployer, nonce_ + 3);
        _addrs.boss = computeCreateAddress(_deployer, nonce_ + 4);
        _addrs.military = computeCreateAddress(_deployer, nonce_ + 5);
        _addrs.governor = computeCreateAddress(_deployer, nonce_ + 6);

        new Bank(_addrs.character, _addrs.marketplace, _addrsExt.layerZeroEndpoint, MockERC20(_addrsExt.usdc));
        _addrs.character = address(
            new CharacterSale(Bank(_addrs.bank), Item(_addrs.item), _addrs.military, _addrs.boss, _addrsExt.layerZeroEndpoint, address(_addrsExt.usdc), _cts.chainId, _cts.nrChains)
        );
        new Item(_addrs.character, _addrs.marketplace, _addrs.boss, _addrsExt.layerZeroEndpoint);
        new Marketplace(Item(_addrs.item), Bank(_addrs.bank));
        new Boss(Item(_addrs.item), CharacterSale(_addrs.character), _addrsExt.link, _addrsExt.vrf2Wrapper, _cts.bossRoundDuration);
        new Military(CharacterSale(_addrs.character), _addrs.bank);

        address[] memory executors = new address[](1);
        executors[0] = address(0);
        TimelockController timelock_ = new TimelockController(10 minutes, new address[](0), executors, _deployer);
        AZWorldsGovernor governor_ = new AZWorldsGovernor(CharacterSale(_addrs.character), timelock_);
        timelock_.grantRole(timelock_.PROPOSER_ROLE(), address(governor_));
        _addrs.governor = address(timelock_);

        MockInvestmentProtocol investmentProtocol_ =
            new MockInvestmentProtocol(MockERC20(_addrsExt.usdc), MockERC20(_addrsExt.rewardToken));
        _addrs.investmentStrategy = address(
            new MockInvestmentStrategy(Bank(_addrs.bank), investmentProtocol_, ISwapRouter(_addrsExt.swapRouter), _cts.poolFee)
        );
        _addrs.investmentProtocol = address(investmentProtocol_);

        Bank(_addrs.bank).setInvestmentStrategy(MockInvestmentStrategy(_addrs.investmentStrategy));

        vm.stopPrank();

        vm.prank(_player1);
        _buyCharacter(_player1, _player1PK);
    }

    function _buyCharacter(address buyer_, uint256 privateKey_) internal returns (uint256) {
        uint256 prevBankBalance_ = MockERC20(_addrsExt.usdc).balanceOf(_addrs.bank);
        uint256 value_ = CharacterSale(_addrs.character).getPrice();

        bytes32 hashedData_ = keccak256(
            abi.encodePacked(
                "\x19\x01",
                MockERC20(_addrsExt.usdc).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        MockERC20(_addrsExt.usdc).TRANSFER_WITH_AUTHORIZATION_TYPEHASH(),
                        buyer_,
                        _addrs.character,
                        value_,
                        0,
                        type(uint256).max,
                        bytes32(_nonces[buyer_])
                    )
                )
            )
        );
        CharacterSale.Signature memory signature_;
        (signature_.v, signature_.r, signature_.s) = vm.sign(privateKey_, hashedData_);

        MockERC20(_addrsExt.usdc).mint(buyer_, value_);

        vm.prank(buyer_);
        uint256 charId_ = CharacterSale(_addrs.character).buy(
            buyer_, value_, 0, type(uint256).max, bytes32(_nonces[buyer_]++), signature_
        );
        assertEq(CharacterSale(_addrs.character).ownerOf(charId_), buyer_);
        assertEq(MockERC20(_addrsExt.usdc).balanceOf(buyer_), 0);
        assertEq(MockERC20(_addrsExt.usdc).balanceOf(address(_addrs.bank)), value_ + prevBankBalance_);
        assertEq(MockERC20(_addrsExt.usdc).balanceOf(address(_addrs.character)), 0);

        return charId_;
    }

    function _mintItem(address player_, uint256 itemId_) internal {
        vm.prank(_addrs.character);
        Item(_addrs.item).mint(player_, itemId_);
    }

    function _mintGold(address player_, uint256 amount_) internal {
        vm.prank(_addrs.character);
        Bank(_addrs.bank).mint(player_, amount_);
    }
}
