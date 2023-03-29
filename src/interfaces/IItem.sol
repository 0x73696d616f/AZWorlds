// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IONFT1155 } from "src/dependencies/layerZero/interfaces/onft1155/IONFT1155.sol";

interface IItem is IONFT1155 {
    event ItemBurned(address indexed from, uint256 id);
    event ItemMinted(address indexed to, uint256 id);
    event ItemBatchBurned(address indexed from, uint256[] ids, uint256[] amounts);
    event ItemBatchMinted(address indexed to, uint256[] ids, uint256[] amounts);
    event ItemPrivilegedTransfer(address indexed from, address indexed to, uint256 id);

    function burn(address from, uint256 id) external;
    function mint(address to, uint256 id) external;
    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;
    function privilegedSafeTransferFrom(address from_, address to_, uint256 id_) external;
}
