// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOwnershipModel.sol";

contract OwnershipModelVanguard3 is IOwnershipModel,Ownable {
    constructor() Ownable(tx.origin) {}
    function checkOwner(address,bytes32) view external override returns (bool) {
        return _msgSender() == owner();
    }
}
