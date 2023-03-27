// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Fixture } from "./Fixture.t.sol";

contract CharacterSaleTest is Fixture {
    function setUp() public virtual override {
        super.setUp();
    }

    function testBuyCharacter() public {
        for (uint256 i = 1; i < 10; i++) {
            assertEq(_buyCharacter(_player1, _player1PK), _cts.chainId + i * _cts.nrChains);
        }
    }
}
