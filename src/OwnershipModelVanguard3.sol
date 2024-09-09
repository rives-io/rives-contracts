// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOwnershipModel.sol";

contract OwnershipModelVanguard3 is IOwnershipModel,Ownable {
    constructor() Ownable(_msgSender()) {}
    function checkOwner(address addr,bytes32) view external override returns (bool) {
        return addr == owner();
    }
}
