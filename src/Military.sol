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

    mapping(uint256 => CharInfo) public _charInfos;
    Deposit[] public _deposits;

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

    function join(IChar.CharInfo calldata charInfo_) external override {
        _char.validateCharInfo(charInfo_, msg.sender);
        uint256 goldPerPower_ = _updateExpiredDeposits();

        _charInfos[charInfo_.charId] = CharInfo(uint224(goldPerPower_), uint32(charInfo_.power));
        _totalPower += charInfo_.power;
    }

    function leave(uint256 charId_) external override {
        if (_char.ownerOf(charId_) != msg.sender && msg.sender != address(_char)) {
            revert NotCharOwnerError(charId_, msg.sender);
        }
        CharInfo memory charInfo_ = _charInfos[charId_];
        if (charInfo_.goldPerPower == 0) revert NotEnlistedError(charId_);

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _totalPower -= charInfo_.power;
        delete _charInfos[charId_];

        IGold(_bank).transfer(msg.sender, (goldPerPower_ - charInfo_.goldPerPower) * charInfo_.power / PRECISION);
    }

    function modifyPower(uint256 charId_, int256 powerChange_) external override {
        if (msg.sender != address(_char)) revert NotCharacterError(msg.sender);
        if (powerChange_ == 0) revert ZeroPowerChangeError(charId_);

        CharInfo memory charInfo_ = _charInfos[charId_];
        if (charInfo_.goldPerPower == 0) revert NotEnlistedError(charId_);

        uint256 goldPerPower_ = _updateExpiredDeposits();

        IGold(_bank).transfer(msg.sender, (goldPerPower_ - charInfo_.goldPerPower) * charInfo_.power / PRECISION);

        charInfo_.goldPerPower = uint224(goldPerPower_);

        if (powerChange_ > 0) {
            _totalPower += uint256(powerChange_);
            charInfo_.power += uint32(uint256(powerChange_));
        } else {
            _totalPower -= uint256(-powerChange_);
            charInfo_.power -= uint32(uint256(-powerChange_));
        }
        _charInfos[charId_] = charInfo_;
    }

    function getRewards(uint256 charId_) public override {
        if (_char.ownerOf(charId_) != msg.sender) revert NotCharOwnerError(charId_, msg.sender);
        CharInfo memory charInfo_ = _charInfos[charId_];
        if (charInfo_.goldPerPower == 0) revert NotEnlistedError(charId_);

        uint256 goldPerPower_ = _updateExpiredDeposits();
        _charInfos[charId_].goldPerPower = uint224(goldPerPower_);

        IGold(_bank).transfer(msg.sender, (goldPerPower_ - charInfo_.goldPerPower) * charInfo_.power / PRECISION);
    }

    function previewRewards(uint256 charId_) external view override returns (uint256) {
        (,, uint256 goldPerPower_,) = _checkExpiredDeposits();
        CharInfo memory charInfo_ = _charInfos[charId_];

        return (goldPerPower_ - charInfo_.goldPerPower) * charInfo_.power / PRECISION;
    }

    function isCharEnlisted(uint256 charId_) external view override returns (bool) {
        return _charInfos[charId_].goldPerPower > 0;
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
