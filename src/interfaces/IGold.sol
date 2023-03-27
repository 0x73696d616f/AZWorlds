// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IOFT } from "src/dependencies/layerZero/interfaces/oft/IOFT.sol";

interface IGold is IOFT {
    error NotPrivilegedSender(address sender);
    error NotCharacterError(address sender);

    function burn(address account_, uint256 amount_) external;
    function mint(address account_, uint256 amount_) external;
    function privilegedTransferFrom(address from_, address to_, uint256 amount_) external;
}
