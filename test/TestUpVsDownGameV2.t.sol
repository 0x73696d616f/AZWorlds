// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { console } from "@forge-std/console.sol";
import { UpVsDownGameV2 } from "src/UpVsDownGameV2.sol";
import { Fixture } from "test/Fixture.t.sol";
import { IPriceFeed } from "src/interfaces/IPriceFeed.sol";
import { Bank } from "src/Bank.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UpVsDownGameV2Test is Fixture {
    function setUp() public override {
        super.setUp();
    }

    function testRound() public {
        UpVsDownGameV2 game_ = UpVsDownGameV2(_game);

        address player1_ = vm.addr(99);
        address player2_ = vm.addr(100);
        vm.label(player1_, "player1");
        vm.label(player2_, "player2");
        _mintGold(player1_, 100);
        _mintGold(player2_, 100);

        vm.warp(10_000);

        vm.prank(_deployer);
        game_.startGame();

        bytes memory poolId_ = abi.encode(0);

        vm.prank(_deployer);
        game_.createPool(poolId_, 0, type(uint256).max, 5);

        UpVsDownGameV2.makeTradeStruct memory trade1_ = UpVsDownGameV2.makeTradeStruct({
            poolId: poolId_,
            avatarUrl: "something",
            countryCode: "US",
            upOrDown: true,
            goldBet: 10
        });

        vm.prank(player1_);
        game_.makeTrade(trade1_);

        UpVsDownGameV2.makeTradeStruct memory trade2_ = UpVsDownGameV2.makeTradeStruct({
            poolId: poolId_,
            avatarUrl: "something",
            countryCode: "US",
            upOrDown: false,
            goldBet: 20
        });

        vm.prank(player2_);
        game_.makeTrade(trade2_);

        assertEq(Bank(_bank).balanceOf(player1_), 90);
        assertEq(Bank(_bank).balanceOf(player2_), 80);
        assertEq(Bank(_bank).balanceOf(_game), 30);

        game_.trigger(poolId_, 2, 10);
        assertEq(game_.isPoolOpen(poolId_), false);
        vm.warp(block.timestamp + uint32(game_.GAME_DURATION()) + 1);
        vm.mockCall(
            _priceFeed, abi.encodeWithSelector(IPriceFeed.getRate.selector, WBTC, USDC, true), abi.encode(27_001)
        );

        vm.prank(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38); //tx.origin
        game_.trigger(poolId_, 2, 20);

        assertEq(Bank(_bank).balanceOf(player1_), 119); // 90 + 30*95/100
        assertEq(Bank(_bank).balanceOf(player2_), 80);
        assertEq(Bank(_bank).balanceOf(_game), 0);
        assertEq(Bank(_bank).balanceOf(_deployer), 1); // 30*5/100
    }

    function testLostGold() public {
        UpVsDownGameV2 game_ = UpVsDownGameV2(_game);

        address player1_ = vm.addr(99);
        address player2_ = vm.addr(100);
        vm.label(player1_, "player1");
        vm.label(player2_, "player2");
        _mintGold(player1_, 100);
        _mintGold(player2_, 100);

        vm.warp(10_000);

        vm.prank(_deployer);
        game_.startGame();

        bytes memory poolId_ = abi.encode(0);

        vm.prank(_deployer);
        game_.createPool(poolId_, 0, type(uint256).max, 5);

        UpVsDownGameV2.makeTradeStruct memory trade1_ = UpVsDownGameV2.makeTradeStruct({
            poolId: poolId_,
            avatarUrl: "something",
            countryCode: "US",
            upOrDown: false,
            goldBet: 10
        });

        vm.prank(player1_);
        game_.makeTrade(trade1_);

        UpVsDownGameV2.makeTradeStruct memory trade2_ = UpVsDownGameV2.makeTradeStruct({
            poolId: poolId_,
            avatarUrl: "something",
            countryCode: "US",
            upOrDown: false,
            goldBet: 20
        });

        vm.prank(player2_);
        game_.makeTrade(trade2_);

        assertEq(Bank(_bank).balanceOf(player1_), 90);
        assertEq(Bank(_bank).balanceOf(player2_), 80);
        assertEq(Bank(_bank).balanceOf(_game), 30);

        game_.trigger(poolId_, 2, 10);
        assertEq(game_.isPoolOpen(poolId_), false);
        vm.warp(block.timestamp + uint32(game_.GAME_DURATION()) + 1);
        vm.prank(_game);
        IERC20(_bank).transfer(_deployer, 30);

        vm.prank(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38); //tx.origin
        game_.trigger(poolId_, 2, 20);
        assertEq(game_.lostGold(player1_), 10);
        assertEq(game_.lostGold(player2_), 20);

        _mintGold(_game, 30);
        vm.prank(player1_);
        game_.claimLostGold();
        assertEq(game_.lostGold(player1_), 0);
        assertEq(Bank(_bank).balanceOf(player1_), 100);
        assertEq(Bank(_bank).balanceOf(_game), 20);
        vm.prank(player2_);
        game_.claimLostGold();
        assertEq(game_.lostGold(player2_), 0);
        assertEq(Bank(_bank).balanceOf(player2_), 100);
        assertEq(Bank(_bank).balanceOf(_game), 0);
    }
}
