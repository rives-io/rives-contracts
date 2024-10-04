// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOwnershipModel.sol";

interface WorldWithFuncs {
    function getCartridgeOwner(bytes32) external view returns (address);
    function getTapeSubmissionModelAddress(bytes32) external view returns (address);
}

contract CartridgeOwnershipModelWithProxy is IOwnershipModel, Ownable {
    address public worldAddress;

    constructor(address ownerAddress) Ownable(ownerAddress) {}

    function checkOwner(address addr, bytes32 cartridgeId) external view override returns (bool) {
        // get cartridge owner from proxy contracts
        return addr == owner() // operator
            || (
                worldAddress != address(0) // cartridge owner
                    && (
                        addr == WorldWithFuncs(worldAddress).getCartridgeOwner(cartridgeId)
                        // automatic from proxy contract
                        || addr == WorldWithFuncs(worldAddress).getTapeSubmissionModelAddress(cartridgeId)
                    )
            );
    }

    function setWorldAddress(address addr) external onlyOwner {
        worldAddress = addr;
    }
}
