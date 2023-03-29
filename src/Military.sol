// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { ICharacter as IChar } from "./interfaces/ICharacter.sol";
import { IGold } from "./interfaces/IGold.sol";
import { IMilitary } from "./interfaces/IMilitary.sol";

contract Military is IMilitary {
    uint256 public constant PRECISION = 1e18;

    IChar public immutable _char;
    address public immutable _bank;

    uint256 public _totalPower;
    uint256 public _lastUpdate;
    uint256 public _goldPerPower = 1;
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
        if (_firstExpiringDeposit != 0) _updateExpiredDeposits();
        else _lastUpdate = block.timestamp;

        _deposits.push(Deposit({ amount: uint104(amount_), expireTimestamp: uint64(block.timestamp + 365 days) }));
        _totalDeposited += amount_;

        emit Deposited(amount_, block.timestamp + 365 days);
        emit TotalDepositedUpdated(_totalDeposited);
    }

    function join(uint256 charId_) external override {
        if (isCharEnlisted(charId_)) revert AlreadyEnlistedError(charId_);
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _goldPerPowerByCharId[charId_] = goldPerPower_;
        _totalPower += charInfo_.power;

        emit TotalPowerUpdated(charInfo_.power);
        emit GoldPerPowerUpdated(goldPerPower_);
        emit GoldPerPowerofCharUpdated(charId_, goldPerPower_);
        emit Joined(charId_, charInfo_.power);
    }

    function leave(uint256 charId_) external override returns (uint256) {
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);
        return _leave(charId_, owner_, charInfo_.power);
    }

    function leave(uint256 charId_, address owner_, uint256 charPower_) external override onlyCharacter {
        _leave(charId_, owner_, charPower_);
    }

    function increasePower(uint256 charId_, address owner_, uint256 oldPower_, uint256 powerIncrease_)
        external
        override
        onlyCharacter
    {
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) return;

        uint256 goldPerPower_ = _updateExpiredDeposits();

        uint256 rewards_ = (goldPerPower_ - goldPerPowerOfChar_) * oldPower_ / PRECISION;
        if (rewards_ != 0) IGold(_bank).transfer(owner_, rewards_);

        _totalPower += powerIncrease_;

        emit RewardsClaimed(charId_, rewards_);
        emit PowerIncreased(charId_, powerIncrease_);
        emit TotalPowerUpdated(oldPower_ + powerIncrease_);
    }

    function getRewards(uint256 charId_) external override returns (uint256 rewards_) {
        (IChar.CharInfo memory charInfo_, address owner_) = _char.getCharInfo(charId_);
        _validateCharOwner(charId_, owner_);

        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) return 0;

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _goldPerPowerByCharId[charId_] = goldPerPower_;

        rewards_ = (goldPerPower_ - goldPerPowerOfChar_) * charInfo_.power / PRECISION;
        if (rewards_ != 0) IGold(_bank).transfer(owner_, rewards_);

        emit GoldPerPowerofCharUpdated(charId_, goldPerPower_);
        emit RewardsClaimed(charId_, rewards_);
    }

    function previewRewards(uint256 charId_) external view override returns (uint256) {
        (IChar.CharInfo memory charInfo_,) = _char.getCharInfo(charId_);
        (,, uint256 goldPerPower_,,) = _checkExpiredDeposits();
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];

        return (goldPerPower_ - goldPerPowerOfChar_) * charInfo_.power / PRECISION;
    }

    function isCharEnlisted(uint256 charId_) public view override returns (bool) {
        return _goldPerPowerByCharId[charId_] > 0;
    }

    function _leave(uint256 charId_, address owner_, uint256 charPower_) internal returns (uint256 rewards_) {
        uint256 goldPerPowerOfChar_ = _goldPerPowerByCharId[charId_];
        if (goldPerPowerOfChar_ == 0) return 0;

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _totalPower -= charPower_;
        delete _goldPerPowerByCharId[charId_];

        rewards_ = (goldPerPower_ - goldPerPowerOfChar_) * charPower_ / PRECISION;
        if (rewards_ != 0) IGold(_bank).transfer(owner_, rewards_);

        emit GoldPerPowerofCharUpdated(charId_, 0);
        emit RewardsClaimed(charId_, rewards_);
    }

    function _validateCharOwner(uint256 charId_, address owner_) internal view {
        if (owner_ != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
    }

    function _onlyCharacter() internal view {
        if (address(_char) != msg.sender) revert NotCharacterError(msg.sender);
    }

    function _checkExpiredDeposits()
        internal
        view
        returns (
            uint256 totalDeposited_,
            uint256 firstExpiringDeposit_,
            uint256 goldPerPower_,
            uint256 lastUpdate_,
            uint256 goldToburn_
        )
    {
        firstExpiringDeposit_ = _firstExpiringDeposit;
        lastUpdate_ = _lastUpdate;
        totalDeposited_ = _totalDeposited;
        goldPerPower_ = _goldPerPower;
        uint256 totalPower_ = _totalPower;
        uint256 depositsLength_ = _deposits.length;
        if (
            firstExpiringDeposit_ >= depositsLength_
                || _deposits[firstExpiringDeposit_].expireTimestamp > block.timestamp
        ) {
            if (totalPower_ == 0) {
                goldToburn_ = (block.timestamp - lastUpdate_) * totalDeposited_ / 365 days;
            } else {
                goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
            }
            lastUpdate_ = block.timestamp;
            return (totalDeposited_, firstExpiringDeposit_, goldPerPower_, lastUpdate_, goldToburn_);
        }

        do {
            Deposit memory deposit_ = _deposits[firstExpiringDeposit_];
            if (deposit_.expireTimestamp > block.timestamp) break;
            if (totalPower_ == 0) {
                goldToburn_ += (block.timestamp - lastUpdate_) * totalDeposited_ / 365 days;
            } else {
                goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
            }
            lastUpdate_ = deposit_.expireTimestamp;
            unchecked {
                totalDeposited_ -= deposit_.amount;
                ++firstExpiringDeposit_;
            }
        } while (firstExpiringDeposit_ < depositsLength_);

        if (totalPower_ == 0) {
            goldToburn_ += (block.timestamp - lastUpdate_) * totalDeposited_ / 365 days;
        } else {
            goldPerPower_ += (block.timestamp - lastUpdate_) * totalDeposited_ * PRECISION / totalPower_ / 365 days;
        }
    }

    function _updateExpiredDeposits() internal returns (uint256 goldPerPower_) {
        uint256 goldToBurn_;
        uint256 firstExpiringDeposit_;
        uint256 totalDeposited_;
        (totalDeposited_, firstExpiringDeposit_, goldPerPower_, _lastUpdate, goldToBurn_) = _checkExpiredDeposits();
        _firstExpiringDeposit = firstExpiringDeposit_;
        _totalDeposited = totalDeposited_;
        _goldPerPower = goldPerPower_;

        if (goldToBurn_ != 0) IGold(_bank).burn(address(this), goldToBurn_);

        emit FirstExpiringDepositUpdated(firstExpiringDeposit_);
        emit GoldPerPowerUpdated(goldPerPower_);
        emit GoldBurned(goldToBurn_);
        emit TotalDepositedUpdated(totalDeposited_);
    }
}
