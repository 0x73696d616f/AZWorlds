// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "@forge-std/Script.sol";
import { MockERC20 } from "test/mocks/MockERC20.sol";
import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { Multicall } from "@uniswap/v3-periphery/contracts/base/Multicall.sol";
import "./utils.sol";

contract Deploy is Script {
    address private _deployerAddress;
    uint256 private _deployerPrivateKey;
    MockERC20 private _usdc;
    MockERC20 private _rewardToken;
    INonfungiblePositionManager private _nonfungiblePositionManager;
    uint24 private _poolFee;

    function setUp() public {
        _deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        _deployerAddress = vm.addr(_deployerPrivateKey);
        _rewardToken = MockERC20(0xCEf7193E05F31EC594dDB4d7ACaaD71D7A26B23e);
        _usdc = MockERC20(0xB53A7F7f4802B83770E4541cd4D1867d8078D995);
        _nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88); // mainnet
        _poolFee = 500;
    }

    /// @dev You can send multiple transactions inside a single script.
    function run() public {
        vm.startBroadcast(_deployerPrivateKey);

        uint256 amount0ToMint = 10_000_000e18;
        uint256 amount1ToMint = amount0ToMint;

        _usdc.approve(address(_nonfungiblePositionManager), type(uint256).max);
        _rewardToken.approve(address(_nonfungiblePositionManager), type(uint256).max);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(_usdc),
            token1: address(_rewardToken),
            fee: _poolFee,
            tickLower: -200,
            tickUpper: 200,
            amount0Desired: amount0ToMint,
            amount1Desired: amount1ToMint,
            amount0Min: 0,
            amount1Min: 0,
            recipient: _deployerAddress,
            deadline: block.timestamp + 100
        });

        bytes memory createCall_ = abi.encodeWithSelector(
            _nonfungiblePositionManager.createAndInitializePoolIfNecessary.selector,
            address(_usdc),
            address(_rewardToken),
            _poolFee,
            encodePriceSqrt(1, 1)
        );

        bytes memory mintCall_ = abi.encodeWithSelector(_nonfungiblePositionManager.mint.selector, params);

        bytes[] memory calls_ = new bytes[](2);
        calls_[0] = createCall_;
        calls_[1] = mintCall_;

        Multicall(address(_nonfungiblePositionManager)).multicall(calls_);

        vm.stopBroadcast();
    }
}
