// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICartridgeModel {
    function decodeCartridgeUser(bytes calldata data) external view returns (bytes32, address);
    function decodeCartridgeMetadata(bytes calldata data) external view returns (bytes32, uint256, bytes32, int256);
}
