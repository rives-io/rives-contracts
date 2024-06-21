// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITapeOwnershipModel {
    function checkOwner(address,bytes32) view external returns (bool);
}
