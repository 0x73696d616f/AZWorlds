// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { toDaysWadUnsafe } from "src/dependencies/linearVRGDA/utils/SignedWadMath.sol";
import { IUSDC } from "./interfaces/IUSDC.sol";
import { IItem } from "./interfaces/IItem.sol";
import { IBank } from "./interfaces/IBank.sol";
import { ICharacterSale } from "./interfaces/ICharacterSale.sol";
import { LinearVRGDA } from "src/dependencies/linearVRGDA/LinearVRGDA.sol";
import { Character } from "./Character.sol";

contract CharacterSale is ICharacterSale, LinearVRGDA, Character {
    address public immutable _usdc;
    uint256 public immutable _chainId;
    uint256 public immutable _nrChains;

    uint256 public totalSold; // The total number of tokens sold so far.
    uint256 public immutable startTime = block.timestamp; // When VRGDA sales begun.

    constructor(
        IBank bank_,
        IItem item_,
        address military_,
        address boss_,
        address lzEndpoint_,
        address usdc_,
        uint8 chainId_,
        uint8 nrChains_
    )
        Character(bank_, item_, lzEndpoint_, military_, boss_)
        LinearVRGDA(
            10e18, // Target price.
            0.31e18, // Price decay percent.
            10e18 // Per time unit.
        )
    {
        _usdc = usdc_;
        IUSDC(_usdc).approve(address(bank_), type(uint256).max);
        _chainId = chainId_;
        _nrChains = nrChains_;
    }

    function buy(
        address from_,
        uint256 usdcSent_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_,
        Signature calldata signature_
    ) external override returns (uint256 mintedId_) {
        unchecked {
            mintedId_ = _chainId + _nrChains * totalSold;
            uint256 price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), totalSold++);

            require(usdcSent_ >= price, "UNDERPAID"); // Don't allow underpaying.

            IUSDC(_usdc).transferWithAuthorization(
                from_,
                address(this),
                usdcSent_,
                validAfter_,
                validBefore_,
                nonce_,
                signature_.v,
                signature_.r,
                signature_.s
            );

            _mint(from_, mintedId_); // Mint the NFT using mintedId.

            _bank.depositAndNotify(price, _military, abi.encodeWithSignature("deposit(uint256)", price));
            if (usdcSent_ - price > 0) IUSDC(_usdc).transfer(from_, usdcSent_ - price);
        }
    }

    function getPrice() external view override returns (uint256 price_) {
        price_ = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), totalSold);
    }
}
