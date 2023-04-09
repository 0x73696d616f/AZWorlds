// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Fixture } from "./Fixture.t.sol";
import { console } from "@forge-std/console.sol";

contract CharacterSaleTest is Fixture {
    function setUp() public virtual override {
        super.setUp();
    }

    function testBuyCharacter() public {
        for (uint256 i = 1; i < 10; i++) {
            assertEq(_buyCharacter(_player1, _player1PK), _chainId + i * _nrChains);
        }
    }

    function testItem() public {
        bytes memory toAddressBytes = abi.encodePacked(0x452264D7341300af83CB52a5fFBb3b0405c1ab62);
        console.logBytes(toAddressBytes);
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }
        console.log(toAddress);
    }
}
