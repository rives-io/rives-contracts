// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITapeOwnershipModel.sol";

contract TapeOwnershipModelVanguard3 is ITapeOwnershipModel {
    function checkOwner(address,bytes32) pure external override returns (bool) {
        return true;
    }
}
