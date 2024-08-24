// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { SystemCallData } from "@latticexyz/world/src/modules/init/types.sol";
 
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";


import { CatridgeAssetAddress, CartridgeCreator, TapeAssetAddress, TapeCreator, DebugCounter, DappMessagesDebug} from "../codegen/index.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface WorldWithFuncs {
  function setNamespaceSystem(address, ResourceId) external;
}

interface RivesAsset {
  function setTapeParams(bytes32) external;
}

contract CoreSystem is System {
  error CoreSystem__NoCartridgeBalance(bytes32);
  error CoreSystem__NoTapeBalance(bytes32);

  bytes4 constant insertCartridgeSelector = bytes4(0x5eab7461);
  bytes4 constant verifySelector = bytes4(0xdb690895);
  bytes4 constant registerVerificationSelector = bytes4(0xa98dfd7f);
  
  function getCartridgeIdFromHash(bytes calldata payloadHash) public pure returns (bytes32) {
    return bytes32(payloadHash[:6]);
  }

  function getCartridgeIdFromVerifyPayload(bytes calldata payload) public pure returns (bytes32) {
    return bytes32(payload[4:10]);
  }

  function getTapeIdFromRuleAndHash(bytes calldata ruleId,bytes calldata payloadHash) public pure returns (bytes32) {
    return bytes32(abi.encodePacked(ruleId[:20],payloadHash[:12]));
  }

  // function getCartridgeIdFromVerifyPayload(bytes calldata payload) public pure returns (bytes32) {
  //   // (bytes32 ruleId, bytes32 outcardHash, bytes tape, int claimScore, bytes32[] tapes, bytes incard)
  //   (bytes32 ruleId, , , , , ) = 
  //     abi.decode(payload, (bytes32,bytes32,bytes,int,bytes32[],bytes));
  //     bytes memory ruleBytes = abi.encodePacked(ruleId);
  //     bytes32 cartridgeId = getCartridgeIdFromBytes(ruleBytes);
  //   return cartridgeId;
  // }

  function getCartridgeCreator(bytes32 cartridgeId) public view returns (address) {
    return CartridgeCreator.get(cartridgeId);
  }

  function getTapeCreator(bytes32 tapeId) public view returns (address) {
    return TapeCreator.get(tapeId);
  }

  function prepareInput(bytes calldata payload) public returns (bool) {

    // get namespace system from db by dapp address
    // ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem");

    uint32 c = DebugCounter.get();
    // DappMessagesDebug.set(c++, "tx.origin", abi.encode(tx.origin));
    // DappMessagesDebug.set(c++, "_msgSender()", abi.encode(_msgSender()));

    // Insert cartridge
    if (insertCartridgeSelector == bytes4(payload[:4])) {
      bytes32 payloadHash = keccak256(abi.decode(payload[4:],(bytes)));
      // DappMessagesDebug.set(c++, "insert payloadHash", abi.encode(payloadHash));
      bytes32 cartridgeId = this.getCartridgeIdFromHash(abi.encodePacked(payloadHash));
      DappMessagesDebug.set(c++, "insert cartridgeId", abi.encode(cartridgeId));
      CartridgeCreator.set(cartridgeId, tx.origin);
      
    } else if (verifySelector == bytes4(payload[:4]) ||
        registerVerificationSelector == bytes4(payload[:4])) {
      DappMessagesDebug.set(c++, "verify rule", abi.encode(payload[4:36]));
      bytes32 cartridgeId = this.getCartridgeIdFromVerifyPayload(payload);
      DappMessagesDebug.set(c++, "verify cartridgeId", abi.encode(cartridgeId));
      if (ERC1155(CatridgeAssetAddress.get()).balanceOf(tx.origin,uint(cartridgeId)) < 1) 
        revert CoreSystem__NoCartridgeBalance(cartridgeId);
      (,,bytes memory tape,,bytes32[] memory tapesUsed,) = abi.decode(payload[4:],(bytes32,bytes32,bytes,int,bytes32[],bytes));
      address tapeAddr = TapeAssetAddress.get();
      for (uint256 i; i < tapesUsed.length; ++i) {
        if (ERC1155(tapeAddr).balanceOf(tx.origin,uint(tapesUsed[i])) < 1) 
          revert CoreSystem__NoTapeBalance(tapesUsed[i]);
      }
      bytes32 payloadHash = keccak256(tape);
      // DappMessagesDebug.set(c++, "verify payloadHash", abi.encode(payloadHash));
      bytes32 tapeId = this.getTapeIdFromRuleAndHash(abi.encodePacked(payload[4:36]), abi.encodePacked(payloadHash));
      DappMessagesDebug.set(c++, "verify tapeId", abi.encode(tapeId));
      TapeCreator.set(tapeId, tx.origin);
      RivesAsset(tapeAddr).setTapeParams(tapeId);
    }
 
    DebugCounter.set(c);

    return true;
  }

  function setDappAddress(address _dapp) public {

    // get namespace system from db by dapp address
    ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem");

    // leave checks for dapp system
   
    // call the update set namespace for a dapp
    WorldWithFuncs(_world()).setNamespaceSystem(_dapp, coreDappSystem);
  }

}
