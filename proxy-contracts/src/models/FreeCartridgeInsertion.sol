// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ICartridgeInsertion } from "../interfaces/ICartridgeInsertion.sol";

contract FreeCartridgeInsertion is ICartridgeInsertion {
  function _getCartridgeIdFromHash(bytes calldata payloadHash) public pure returns (bytes32) {
    return bytes32(payloadHash[:6]);
  }

  function validateConfig(
      bytes calldata config) external pure returns (bool) {
    if (config.length != 0) revert CartridgeInsertion__InvalidConfig("length");
    return true;
  }

  function validateCartridgeInsertion(
      address,bytes calldata payload, bytes calldata) 
      external view returns (bytes32) {
    bytes32 payloadHash = keccak256(abi.decode(payload[4:],(bytes)));
    bytes32 cartridgeId = this._getCartridgeIdFromHash(abi.encodePacked(payloadHash));
    return cartridgeId;
  }

}
