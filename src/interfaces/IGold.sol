// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IOFT } from "src/dependencies/layerZero/interfaces/oft/IOFT.sol";

interface IGold is IOFT {
    error NotPrivilegedSender(address sender);
    error NotCharacterError(address sender);

    event GoldBurned(address indexed account, uint256 amount);
    event GoldMinted(address indexed account, uint256 amount);
    event GoldPrivilegedTransfer(address indexed from, address indexed to, uint256 amount);

    function burn(address account_, uint256 amount_) external;
    function mint(address account_, uint256 amount_) external;
    function privilegedTransferFrom(address from_, address to_, uint256 amount_) external;
}
