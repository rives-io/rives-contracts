// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IOwnershipModel.sol";

contract OwnershipModelVanguard3 is IOwnershipModel {
    function checkOwner(address,bytes32) pure external override returns (bool) {
        return true;
    }
}
