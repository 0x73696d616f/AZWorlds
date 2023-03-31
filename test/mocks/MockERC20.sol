// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { EIP712 } from "src/dependencies/EIP3009/EIP712.sol";
import { EIP3009 } from "src/dependencies/EIP3009/EIP3009.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is EIP3009 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        //DOMAIN_SEPARATOR = 0x19d64970ae67135faab873f0abe76a5ee18734cb628c32659f75b220300d19a5;
        DOMAIN_SEPARATOR = EIP712.makeDomainSeparator(name_, "1");
        _mint(msg.sender, 1_000_000_000_000_000e18);
    }

    function mint(address account_, uint256 amount_) external {
        if (amount_ > 1000e18) return;
        _mint(account_, amount_);
    }
}
