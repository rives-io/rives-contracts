// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOwnershipModel.sol";

interface WorldWithFuncs {
  function getCartridgeCreator(bytes32) view external returns (address);
}

contract CartridgeOwnershipModelVanguard4 is IOwnershipModel,Ownable {

    address public worldAddress;

    constructor() Ownable(tx.origin) {}

    function checkOwner(address addr,bytes32 cartridgeId) view external override returns (bool) {
        // get cartridge owner from proxy contracts
        return addr == owner() || (worldAddress != address(0) && addr == WorldWithFuncs(worldAddress).getCartridgeCreator(cartridgeId));
    }

    function setWorldAddress(address addr) external onlyOwner {
        worldAddress = addr;
    }

}
