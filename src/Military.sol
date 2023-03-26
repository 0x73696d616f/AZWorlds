// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as IChar } from "./interfaces/ICharacter.sol";
import { IGold } from "./interfaces/IGold.sol";
import { IMilitary } from "./interfaces/IMilitary.sol";

contract Military is IMilitary {
    uint256 constant PRECISION = 1e18;

    IChar public immutable _char;
    address public immutable _bank;

    uint256 public _totalPower;
    uint256 public _lastUpdate;
    uint256 public _goldPerPower;
    uint256 public _firstExpiringDeposit;
    uint256 public _totalDeposited;

    mapping(uint256 => uint256) public _goldPerPowerByCharId;
    Deposit[] public _deposits;

    modifier onlyCharacter() {
        _onlyCharacter();
        _;
    }

    constructor(IChar character_, address bank_) {
        _char = character_;
        _bank = bank_;
    }

    function deposit(uint256 amount_) external override {
        if (msg.sender != _bank) revert NotBankError(msg.sender);
        _updateExpiredDeposits();

        _deposits.push(Deposit({ amount: uint104(amount_), expireTimestamp: uint64(block.timestamp + 365 days) }));
        _totalDeposited += amount_;
    }

    function join(uint256 charId_) external override {
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);
        uint256 goldPerPower_ = _updateExpiredDeposits();
        _goldPerPowerByCharId[charId_] = goldPerPower_;
        _totalPower += charInfo_.power;
    }

    function leave(uint256 charId_) external override {
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);
        _leave(charId_, owner_, charInfo_.power);
    }

    function leave(uint256 charId_, address owner_, uint256 charPower_) external override onlyCharacter {
        _leave(charId_, owner_, charPower_);
    }

    function modifyPower(uint256 charId_, address owner_, uint256 oldPower_, int256 powerChange_)
        external
        override
        onlyCharacter
    {
        if (powerChange_ == 0) revert ZeroPowerChangeError(charId_);

        uint256 goldPerPowerOfChar_ = _getGoldPerPowerOfChar(charId_);

        uint256 goldPerPower_ = _updateExpiredDeposits();

        IGold(_bank).transfer(owner_, (goldPerPower_ - goldPerPowerOfChar_) * oldPower_ / PRECISION);

        _totalPower += powerChange_ > 0 ? uint256(powerChange_) : uint256(-powerChange_);
    }

    function getRewards(uint256 charId_) external override {
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);

        uint256 goldPerPowerOfChar_ = _getGoldPerPowerOfChar(charId_);

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _goldPerPowerByCharId[charId_] = goldPerPower_;

        IGold(_bank).transfer(owner_, (goldPerPower_ - goldPerPowerOfChar_) * charInfo_.power / PRECISION);
    }

    function previewRewards(uint256 charId_) external view override returns (uint256) {
        (IChar.CharInfo memory charInfo_,) = _char.getCharInfo(charId_);
        (,, uint256 goldPerPower_,) = _checkExpiredDeposits();
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];

        return (goldPerPower_ - goldPerPowerOfChar_) * charInfo_.power / PRECISION;
    }

    function isCharEnlisted(uint256 charId_) public view override returns (bool) {
        return _goldPerPowerByCharId[charId_] > 0;
    }

    function _leave(uint256 charId_, address owner_, uint256 charPower_) internal {
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) revert NotEnlistedError(charId_);

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _totalPower -= charPower_;
        delete _goldPerPowerByCharId[charId_];

        IGold(_bank).transfer(owner_, (goldPerPower_ - goldPerPowerOfChar_) * charPower_ / PRECISION);
    }

    function _validateCharOwner(uint256 charId_, address owner_) internal view {
        if (owner_ != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
    }

    function _onlyCharacter() internal view {
        if (address(_char) != msg.sender) revert NotCharacterError(msg.sender);
    }

    function _getGoldPerPowerOfChar(uint256 charId_) internal view returns (uint256 goldPerPowerOfChar_) {
        goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) revert NotEnlistedError(charId_);
    }

    function _checkExpiredDeposits()
        internal
        view
        returns (uint256 totalDeposited_, uint256 firstExpiringDeposit_, uint256 goldPerPower_, uint256 lastUpdate_)
    {
        firstExpiringDeposit_ = _firstExpiringDeposit;
        lastUpdate_ = _lastUpdate;
        totalDeposited_ = _totalDeposited;
        goldPerPower_ = _goldPerPower;
        uint256 totalPower_ = _totalPower;
        if (_deposits[firstExpiringDeposit_].expireTimestamp > block.timestamp) {
            lastUpdate_ = block.timestamp;
            goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
            return (totalDeposited_, firstExpiringDeposit_, goldPerPower_, lastUpdate_);
        }

        uint256 depositsLength_ = _deposits.length;
        do {
            Deposit memory deposit_ = _deposits[firstExpiringDeposit_];
            if (deposit_.expireTimestamp > block.timestamp) break;
            goldPerPower_ +=
                (deposit_.expireTimestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
            lastUpdate_ = deposit_.expireTimestamp;
            unchecked {
                totalDeposited_ -= deposit_.amount;
                ++firstExpiringDeposit_;
            }
        } while (firstExpiringDeposit_ < depositsLength_);
        goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
    }

    function _updateExpiredDeposits() internal returns (uint256 goldPerPower_) {
        (_totalDeposited, _firstExpiringDeposit, goldPerPower_, _lastUpdate) = _checkExpiredDeposits();
        _goldPerPower = goldPerPower_;
    }
}
