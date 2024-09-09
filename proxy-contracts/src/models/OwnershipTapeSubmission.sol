// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { ITapeSubmission } from "../interfaces/ITapeSubmission.sol";

interface RivesAsset {
  function setTapeParams(bytes32) external;
  function exists(bytes32) external view returns (bool);
}

interface WorldWithFuncs {
  // function getCartridgeOwner(bytes32) view external returns (address);
  function core__getCartridgeAssetAddress() view external returns (address);
  function core__getTapeAssetAddress() view external returns (address);
  function core__getSystem(bytes16) view external returns (address);
}


// interface WorldWithFuncs {
//   function getTapeCreator(bytes32) view external returns (address);
// }

contract OwnershipTapeSubmission is ITapeSubmission,Ownable {
  error OwnershipTapeSubmission__NotPermitted();

  address public worldAddress;
  bytes16 constant coreSystem = bytes16("CoreSystem");
  bytes16 constant inputSystem = bytes16("InputSystem");

  constructor(address ownerAddress) Ownable(ownerAddress) {}

  function setWorldAddress(address addr) external onlyOwner {
    worldAddress = addr;
  }

  function getTapeIdFromRuleAndHash(bytes calldata ruleId,bytes calldata payloadHash) public pure returns (bytes32) {
    return bytes32(abi.encodePacked(ruleId[:20],payloadHash[:12]));
  }

  function getCartridgeIdFromConfigPayload(bytes calldata payload) public pure returns (bytes32) {
    return bytes32(payload[4:36]);
  }

  function validateConfig(
      bytes32 cartridgeId,
      bytes calldata config) external returns (bool) {
    if (_msgSender() != WorldWithFuncs(worldAddress).core__getSystem(coreSystem)) revert OwnershipTapeSubmission__NotPermitted();
    if (!RivesAsset(WorldWithFuncs(worldAddress).core__getCartridgeAssetAddress()).exists(cartridgeId)) {
      (address cartridgeAddress, bytes memory payload,) = abi.decode(config,(address,bytes,uint256));
      if (cartridgeId != this.getCartridgeIdFromConfigPayload(payload))
        revert TapeSubmission__InvalidConfig("id");
      (bool success,) = cartridgeAddress.call(payload);
      if (!success) revert TapeSubmission__InvalidConfig("setup");
    }
    return true;
  }

  function validateTapeSubmission(
      address user,uint256,bytes32 cartridgeId,bytes calldata payload, bytes calldata) 
      external view returns (bytes32) {
    if (_msgSender() != WorldWithFuncs(worldAddress).core__getSystem(inputSystem)) revert OwnershipTapeSubmission__NotPermitted();
    
    if (ERC1155(WorldWithFuncs(worldAddress).core__getCartridgeAssetAddress()).balanceOf(user,uint(cartridgeId)) < 1) 
      revert TapeSubmission__CannotSubmit("No cartridge Balance");

    (,,bytes memory tape,,bytes32[] memory tapesUsed,) = abi.decode(payload[4:],(bytes32,bytes32,bytes,int,bytes32[],bytes));

    address tapeAddr = WorldWithFuncs(worldAddress).core__getTapeAssetAddress();

    for (uint256 i; i < tapesUsed.length; ++i) {
      if (ERC1155(tapeAddr).balanceOf(user,uint(tapesUsed[i])) < 1) 
        revert TapeSubmission__CannotSubmit("No tape Balance");
    }

    bytes32 payloadHash = keccak256(tape);
    bytes32 tapeId = this.getTapeIdFromRuleAndHash(abi.encodePacked(payload[4:36]), abi.encodePacked(payloadHash));

    return tapeId;
  }

  function prepareTapeSubmission(
      bytes32 tapeId, bytes calldata config) 
      external returns (bool) {
    if (_msgSender() != WorldWithFuncs(worldAddress).core__getSystem(inputSystem)) revert OwnershipTapeSubmission__NotPermitted();
    (,,uint256 setTapeParams) = abi.decode(config,(address,bytes,uint256));
    if (setTapeParams != 0) {
      address tapeAddr = WorldWithFuncs(worldAddress).core__getTapeAssetAddress();
      if (!RivesAsset(tapeAddr).exists(tapeId)) { 
        RivesAsset(tapeAddr).setTapeParams(tapeId);
      // } else { // duplicate
      //   revert TapeSubmission__CannotSubmit("duplicate asset");
      }
    }
    return true;
  }

}
