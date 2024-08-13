// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOwnershipModel.sol";

interface WorldWithFuncs {
  function getTapeCreator(bytes32) view external returns (address);
}

contract TapeOwnershipModelVanguard4 is IOwnershipModel,Ownable {

    address public worldAddress = address(0x00124590193FCD497c0eeD517103368113F89258);

    constructor() Ownable(tx.origin) {}

    function checkOwner(address addr,bytes32 tapeId) view external override returns (bool) {
        // get cartridge owner from proxy contracts
        return addr == owner() || addr == WorldWithFuncs(worldAddress).getTapeCreator(tapeId);
    }

    function setWorldAddress(address addr) external onlyOwner {
        worldAddress = addr;
    }

}
