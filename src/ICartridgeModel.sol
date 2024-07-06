// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICartridgeModel {
    function decodeCartridgeUser(bytes calldata data) view external returns (bytes32,address);
    function decodeCartridgeMetadata(bytes calldata data) view external returns (bytes32, uint, bytes32, int);
}
