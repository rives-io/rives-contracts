// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITapeModel {
    error Tape__ErrorCode();
    function getRoyaltiesTapes(bytes calldata data) pure external returns (bytes32[] memory);
    function decodeTapeUsers(bytes calldata data) pure external returns (bytes32,address,address);
    function decodeTapeMetadata(bytes calldata data) pure external returns (bytes32, bytes32, int, bytes32, int, bytes32, int);
}
