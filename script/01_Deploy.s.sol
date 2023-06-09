// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TimelockController } from "@openzeppelin/contracts/governance/TimelockController.sol";
import { AZWorldsGovernor } from "src/AZWorldsGovernor.sol";
import { Character } from "src/Character.sol";
import { CharacterSale } from "src/CharacterSale.sol";
import { Bank } from "src/Bank.sol";
import { Item } from "src/Item.sol";
import { Marketplace } from "src/Marketplace.sol";
import { Boss } from "src/Boss.sol";
import { Military } from "src/Military.sol";
import { MockInvestmentProtocol } from "test/mocks/MockInvestmentProtocol.sol";
import { MockInvestmentStrategy } from "test/mocks/MockInvestmentStrategy.sol";
import { MockSwapRouter } from "test/mocks/MockSwapRouter.sol";
import { RewardToken } from "test/mocks/RewardToken.sol";
import { USDC } from "test/mocks/USDC.sol";
import { MockPriceFeed } from "test/mocks/MockPriceFeed.sol";
import { CharacterPortal } from "src/CharacterPortal.sol";

import { UpVsDownGameV2 } from "src/UpVsDownGameV2.sol";

import { IPriceFeed } from "src/interfaces/IPriceFeed.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract Deploy is Script {
    uint256 private _deployerPrivateKey;
    address private _deployerAddress;

    // BLOCKCHAIN SPECIFIC CONSTANTS
    // LAYER ZERO
    address private constant LAYER_ZERO_ADDRESS_SEPOLIA = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
    address private constant LAYER_ZERO_ADDRESS_MUMBAI = 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8;
    address private constant LAYER_ZERO_ADDRESS_GOERLI = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23;
    uint16 private constant LAYER_ZERO_CHAIN_ID_SEPOLIA = 10_161;
    uint16 private constant LAYER_ZERO_CHAIN_ID_MUMBAI = 10_109;
    uint16 private constant LAYER_ZERO_CHAIN_ID_GOERLI = 10_121;
    // CHAINLINK
    address private constant LINK_ADDRESS_SEPOLIA = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address private constant LINK_ADDRESS_MUMBAI = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address private constant LINK_ADDRESS_GOERLI = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address private constant VRF2_WRAPPER_ADDRESS_SEPOLIA = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;
    address private constant VRF2_WRAPPER_ADDRESS_MUMBAI = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;
    address private constant VRF2_WRAPPER_ADDRESS_GOERLI = 0x708701a1DfF4f478de54383E49a627eD4852C816;
    // CHAINID STARTING CHAR
    uint8 private constant CHAINID_STARTING_CHAR_SEPOLIA = 1;
    uint8 private constant CHAINID_STARTING_CHAR_MUMBAI = 2;
    uint8 private constant CHAINID_STARTING_CHAR_GOERLI = 3;

    address private constant _layerZeroEndpoint = LAYER_ZERO_ADDRESS_SEPOLIA;
    uint16 private constant _layerZeroChainId = LAYER_ZERO_CHAIN_ID_SEPOLIA;
    address private constant _link = LINK_ADDRESS_SEPOLIA;
    address private constant _vrf2Wrapper = VRF2_WRAPPER_ADDRESS_SEPOLIA;
    uint16 private constant _trustedChain1 = LAYER_ZERO_CHAIN_ID_MUMBAI;
    uint16 private constant _trustedChain2 = LAYER_ZERO_CHAIN_ID_GOERLI;
    uint8 private constant _chainId = CHAINID_STARTING_CHAR_SEPOLIA;

    uint8 private constant _nrChains = 3;
    address private constant _WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 private _bossRoundDuration = 5 minutes;
    uint24 private constant _poolFee = 500;
    uint8 private constant _characterFee = 20;

    USDC private _usdc;
    RewardToken private _rewardToken;
    ISwapRouter private _swapRouter;

    address private _game;
    address private _character;
    address private _item;
    address private _bank;
    address private _marketplace;
    address private _boss;
    address private _military;
    address payable private _timelock;
    address private _governor;
    address private _investmentProtocol;
    address private _investmentStrategy;
    address private _priceFeed;

    function setUp() public {
        _deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        _deployerAddress = vm.addr(_deployerPrivateKey);
    }

    function run() public {
        vm.startBroadcast(_deployerPrivateKey);
        _deploy();
        vm.stopBroadcast();
    }

    function _deploy() internal {
        //_swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _swapRouter = ISwapRouter(address(new MockSwapRouter())); // Sepolia has no uniswap
        _rewardToken = new RewardToken();
        _usdc = new USDC();

        uint64 nonce_ = vm.getNonce(_deployerAddress);
        _bank = computeCreateAddress(_deployerAddress, nonce_);
        _character = computeCreateAddress(_deployerAddress, nonce_ + 1);
        _item = computeCreateAddress(_deployerAddress, nonce_ + 2);
        _marketplace = computeCreateAddress(_deployerAddress, nonce_ + 3);
        _boss = computeCreateAddress(_deployerAddress, nonce_ + 4);
        _military = computeCreateAddress(_deployerAddress, nonce_ + 5);
        _timelock = payable(computeCreateAddress(_deployerAddress, nonce_ + 6));
        _governor = computeCreateAddress(_deployerAddress, nonce_ + 7);
        _investmentProtocol = computeCreateAddress(_deployerAddress, nonce_ + 8);
        _investmentStrategy = computeCreateAddress(_deployerAddress, nonce_ + 9);
        _priceFeed = computeCreateAddress(_deployerAddress, nonce_ + 10);
        _game = computeCreateAddress(_deployerAddress, nonce_ + 11);

        vm.writeFile("script/ContractsDeployed.txt", "");
        vm.writeLine("script/ContractsDeployed.txt", "Addresses");
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_bank));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_character));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_item));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_marketplace));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_boss));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_military));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_timelock));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_governor));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_investmentProtocol));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_investmentStrategy));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_priceFeed));
        vm.writeLine("script/ContractsDeployed.txt", vm.toString(_game));

        vm.label(address(_swapRouter), "SwapRouter");
        vm.label(address(_rewardToken), "RewardToken");
        vm.label(address(_usdc), "USDC");
        vm.label(_bank, "Bank");
        vm.label(_character, "CharacterSale");
        vm.label(_item, "Item");
        vm.label(_marketplace, "Marketplace");
        vm.label(_boss, "Boss");
        vm.label(_military, "Military");
        vm.label(_timelock, "Timelock");
        vm.label(_governor, "Governor");
        vm.label(_investmentProtocol, "InvestmentProtocol");
        vm.label(_investmentStrategy, "InvestmentStrategy");
        vm.label(_priceFeed, "PriceFeed");
        vm.label(_game, "Game");

        new Bank(_character, _marketplace, _military, _layerZeroEndpoint, _usdc, _game);
        new CharacterSale(Bank(_bank ), Item(_item), _military, _boss, _layerZeroEndpoint, address(_usdc), _chainId, _nrChains, _characterFee);

        new Item(_character, _marketplace, _boss, _layerZeroEndpoint);
        new Marketplace(Item(_item), Bank(_bank));
        new Boss(Item(_item), CharacterSale(_character), _link, _vrf2Wrapper, _bossRoundDuration);
        new Military(CharacterSale(_character), _bank);

        // Deploy a new TimelockGovernor contract.
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        new TimelockController(10 minutes, new address[](0), executors, _deployerAddress);
        new AZWorldsGovernor(CharacterSale(_character), TimelockController(_timelock));

        new MockInvestmentProtocol(_usdc, _rewardToken);
        new MockInvestmentStrategy(Bank(_bank), MockInvestmentProtocol(_investmentProtocol), _swapRouter, _poolFee);

        new MockPriceFeed();
        new UpVsDownGameV2(Bank(_bank), IPriceFeed(_priceFeed), IERC20(_WBTC), IERC20(_USDC));

        TimelockController(payable(_timelock)).grantRole(TimelockController(_timelock).PROPOSER_ROLE(), _governor);

        Bank(_bank).setInvestmentStrategy(MockInvestmentStrategy(_investmentStrategy));

        Bank(_bank).setTrustedRemote(_trustedChain1, abi.encodePacked(address(_bank), address(_bank)));
        Bank(_bank).setTrustedRemote(_trustedChain2, abi.encodePacked(address(_bank), address(_bank)));

        Item(_item).setTrustedRemote(_trustedChain1, abi.encodePacked(address(_item), address(_item)));
        Item(_item).setTrustedRemote(_trustedChain2, abi.encodePacked(address(_item), address(_item)));

        CharacterPortal _characterPortal = Character(_character).portal();

        _characterPortal.setTrustedRemote(
            _trustedChain1, abi.encodePacked(address(_characterPortal), address(_characterPortal))
        );
        _characterPortal.setTrustedRemote(
            _trustedChain2, abi.encodePacked(address(_characterPortal), address(_characterPortal))
        );
        _characterPortal.setMinDstGas(_trustedChain1, 1, 1);
        _characterPortal.setMinDstGas(_trustedChain2, 1, 1);
    }
}
