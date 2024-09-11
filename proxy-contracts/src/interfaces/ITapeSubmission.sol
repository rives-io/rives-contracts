// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITapeSubmission {
  error TapeSubmission__InvalidConfig(string reason);
  error TapeSubmission__CannotSubmit(string reason);

  function validateConfig(
    bytes32 cartridgeId,
    bytes calldata config) external returns (bool);

  function validateTapeSubmission(
    address user, uint256 value, bytes32 cartridgeId, bytes calldata payload, bytes calldata config) 
    external returns (bytes32);

  function prepareTapeSubmission(
    bytes32 tapeId, bytes calldata config) 
    external returns (bool);
}
