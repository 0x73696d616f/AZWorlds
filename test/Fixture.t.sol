// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "@forge-std/Test.sol";
import { console } from "@forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { MockPriceFeed } from "test/mocks/MockPriceFeed.sol";
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
import { UpVsDownGameV2 } from "src/UpVsDownGameV2.sol";

import { IPriceFeed } from "src/interfaces/IPriceFeed.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Fixture is Test {
    address internal _swapRouter;
    address internal _usdc;
    address internal _rewardToken;

    address internal _character;
    address internal _item;
    address internal _bank;
    address internal _marketplace;
    address internal _boss;
    address internal _military;
    address internal _investmentProtocol;
    address internal _investmentStrategy;
    address internal _governor;
    address internal _game;

    address internal immutable _deployer;
    uint256 internal immutable _player1PK;
    address internal immutable _player1;
    uint256 internal immutable _player1CharId;
    address internal constant _layerZeroEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
    address internal constant _link = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address internal constant _vrf2Wrapper = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;
    address internal _priceFeed;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint8 internal constant _nrChains = 3;
    uint8 internal constant _chainId = 1;
    uint256 internal constant _bossRoundDuration = 5 minutes;
    uint24 internal constant _poolFee = 500;
    uint8 internal constant _gameControllerFeePercentage = 20;

    mapping(address => uint256) _nonces;

    constructor() {
        _deployer = vm.addr(1);
        _player1PK = 2;
        _player1 = vm.addr(2);
        _player1CharId = 1;
    }

    function setUp() public virtual {
        vm.deal(_deployer, 10 ether);
        vm.deal(_player1, 10 ether);
        vm.label(_deployer, "deployer");
        vm.label(_player1, "player1");
        vm.startPrank(_deployer);
        _swapRouter = address(new MockSwapRouter());
        _usdc = address(new MockERC20("Mock USD Coin", "USDC"));
        _rewardToken = address(new MockERC20("Mock Reward Token", "MRT"));

        uint64 nonce_ = vm.getNonce(_deployer);
        _bank = computeCreateAddress(_deployer, nonce_);
        _character = computeCreateAddress(_deployer, nonce_ + 1);
        _item = computeCreateAddress(_deployer, nonce_ + 2);
        _marketplace = computeCreateAddress(_deployer, nonce_ + 3);
        _boss = computeCreateAddress(_deployer, nonce_ + 4);
        _military = computeCreateAddress(_deployer, nonce_ + 5);
        _governor = computeCreateAddress(_deployer, nonce_ + 6); //timelock
        _game = computeCreateAddress(_deployer, nonce_ + 11);

        new Bank(_character, _marketplace, _military, _layerZeroEndpoint, MockERC20(_usdc), _game);
        _character = address(
            new CharacterSale(Bank(_bank), Item(_item), _military, _boss, _layerZeroEndpoint, address(_usdc), _chainId, _nrChains, _gameControllerFeePercentage)
        );
        new Item(_character, _marketplace, _boss, _layerZeroEndpoint);
        new Marketplace(Item(_item), Bank(_bank));
        new Boss(Item(_item), CharacterSale(_character), _link, _vrf2Wrapper, _bossRoundDuration);
        new Military(CharacterSale(_character), _bank);

        address[] memory executors = new address[](1);
        executors[0] = address(0);
        TimelockController timelock_ = new TimelockController(10 minutes, new address[](0), executors, _deployer);
        AZWorldsGovernor governor_ = new AZWorldsGovernor(CharacterSale(_character), timelock_);
        timelock_.grantRole(timelock_.PROPOSER_ROLE(), address(governor_));

        _investmentProtocol = address(new MockInvestmentProtocol(MockERC20(_usdc), MockERC20(_rewardToken)));
        _investmentStrategy = address(
            new MockInvestmentStrategy(Bank(_bank), MockInvestmentProtocol(_investmentProtocol), ISwapRouter(_swapRouter), _poolFee)
        );

        Bank(_bank).setInvestmentStrategy(MockInvestmentStrategy(_investmentStrategy));

        _priceFeed = address(new MockPriceFeed());
        new UpVsDownGameV2(Bank(_bank), IPriceFeed(_priceFeed), IERC20(WBTC), IERC20(USDC));

        vm.label(_bank, "bank");
        vm.label(_character, "character");
        vm.label(_item, "item");
        vm.label(_marketplace, "marketplace");
        vm.label(_boss, "boss");
        vm.label(_military, "military");
        vm.label(_governor, "governor");
        vm.label(_investmentStrategy, "investmentStrategy");
        vm.label(_investmentProtocol, "investmentProtocol");
        vm.label(_layerZeroEndpoint, "layerZeroEndpoint");
        vm.label(_link, "link");
        vm.label(_vrf2Wrapper, "vrf2Wrapper");
        vm.label(_swapRouter, "swapRouter");
        vm.label(_usdc, "usdc");
        vm.label(_rewardToken, "rewardToken");
        vm.label(_priceFeed, "priceFeed");
        vm.label(WBTC, "wbtc");
        vm.label(USDC, "usdc");
        vm.label(_game, "game");

        vm.stopPrank();

        vm.prank(_player1);
        _buyCharacter(_player1, _player1PK);
    }

    function _buyCharacter(address buyer_, uint256 privateKey_) internal returns (uint256) {
        uint256 prevBankBalance_ = MockERC20(_usdc).balanceOf(_bank);
        uint256 prevDeployerBalance_ = MockERC20(_usdc).balanceOf(_deployer);

        uint256 value_ = CharacterSale(_character).getPrice();

        CharacterSale.Signature memory signature_ = _getSignature(value_, buyer_, privateKey_);

        MockERC20(_usdc).mint(buyer_, value_);

        vm.prank(buyer_);
        uint256 charId_ =
            CharacterSale(_character).buy(buyer_, value_, 0, type(uint256).max, bytes32(_nonces[buyer_]++), signature_);
        assertEq(CharacterSale(_character).ownerOf(charId_), buyer_);
        assertEq(MockERC20(_usdc).balanceOf(buyer_), 0);
        uint256 deployerFee_ = value_ * CharacterSale(_character).gameControllerFeePercentage() / 100;
        assertEq(MockERC20(_usdc).balanceOf(_deployer), prevDeployerBalance_ + deployerFee_);
        assertEq(MockERC20(_usdc).balanceOf(_bank), prevBankBalance_ + value_ - deployerFee_);
        assertEq(MockERC20(_usdc).balanceOf(address(_character)), 0);
        return charId_;
    }

    function _mintItem(address player_, uint256 itemId_) internal {
        vm.prank(_character);
        Item(_item).mint(player_, itemId_);
    }

    function _mintGold(address player_, uint256 amount_) internal {
        vm.prank(_character);
        Bank(_bank).mint(player_, amount_);
    }

    function _getSignature(uint256 value_, address buyer_, uint256 privateKey_)
        internal
        view
        returns (CharacterSale.Signature memory signature_)
    {
        bytes32 hashedMessage = keccak256(
            abi.encode(
                MockERC20(_usdc).TRANSFER_WITH_AUTHORIZATION_TYPEHASH(),
                buyer_,
                _character,
                value_,
                0,
                type(uint256).max,
                bytes32(_nonces[buyer_])
            )
        );

        bytes32 dataHash_ = keccak256(abi.encodePacked("\x19\x01", MockERC20(_usdc).DOMAIN_SEPARATOR(), hashedMessage));
        (signature_.v, signature_.r, signature_.s) = vm.sign(privateKey_, dataHash_);
    }
}
