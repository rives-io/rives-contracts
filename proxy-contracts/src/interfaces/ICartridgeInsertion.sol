// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICartridgeInsertion {
  error CartridgeInsertion__InvalidConfig(string reason);
  error CartridgeInsertion__CannotInsert(string reason);

  function validateConfig(
    bytes calldata config) external returns (bool);

  function validateCartridgeInsertion(
    address user, bytes calldata payload, bytes calldata config) 
    external returns (bytes32);

}
