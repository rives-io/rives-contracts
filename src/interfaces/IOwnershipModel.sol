// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOwnershipModel {
    function checkOwner(address, bytes32) external view returns (bool);
}
