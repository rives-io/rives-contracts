// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ITapeSubmission } from "../interfaces/ITapeSubmission.sol";

contract FreeTapeSubmission is ITapeSubmission {

  function getCartridgeIdFromVerifyPayload(bytes calldata payload) public pure returns (bytes32) {
    return bytes32(payload[4:10]);
  }

  function getTapeIdFromRuleAndHash(bytes calldata ruleId,bytes calldata payloadHash) public pure returns (bytes32) {
    return bytes32(abi.encodePacked(ruleId[:20],payloadHash[:12]));
  }

  function validateConfig(
      bytes32,bytes calldata) external pure returns (bool) {
    return true;
  }

  function validateTapeSubmission(
      address,uint256,bytes32, bytes calldata payload, bytes calldata) 
      external view returns (bytes32) {
    
    (,,bytes memory tape,,,) = abi.decode(payload[4:],(bytes32,bytes32,bytes,int,bytes32[],bytes));

    bytes32 payloadHash = keccak256(tape);
    // DappMessagesDebug.set(c++, "verify payloadHash", abi.encode(payloadHash));
    bytes32 tapeId = this.getTapeIdFromRuleAndHash(abi.encodePacked(payload[4:36]), abi.encodePacked(payloadHash));

    return tapeId;
  }

  function prepareTapeSubmission(
      bytes32, bytes calldata) 
      external pure returns (bool) {
    return true;
  }

}
