// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { Bank } from "./Bank.sol";
import { IInvestmentStrategy } from "./interfaces/IInvestmentStrategy.sol";

abstract contract InvestmentStrategy is IInvestmentStrategy {
    Bank public bank;

    modifier onlyBank() {
        _onlyBank();
        _;
    }

    constructor(Bank bank_) {
        bank = bank_;
    }

    function invest(uint256 amount_) external virtual override onlyBank { }

    function claimRewards() external virtual override onlyBank returns (uint256) { }

    function previewRewards() external view virtual override returns (uint256) { }

    function withdraw(uint256 amount_) external virtual override onlyBank { }

    function getTotalStaked() external view virtual override returns (uint256) { }

    function _onlyBank() internal view {
        if (msg.sender != address(bank)) revert NotBankError(msg.sender);
    }
}
