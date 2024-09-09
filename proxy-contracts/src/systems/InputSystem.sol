// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { SystemCallData } from "@latticexyz/world/src/modules/init/types.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { Systems } from "@latticexyz/world/src/codegen/index.sol";
import { Balances } from "@latticexyz/world/src/codegen/tables/Balances.sol";
 

import { WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";

import { IWorld } from "../codegen/world/IWorld.sol";

import { CartridgeOwner, TapeCreator, NamespaceDappAddress, 
         DebugCounter, DappMessagesDebug} from "../codegen/index.sol";

import { CartridgeInsertionModel, CartridgeInsertionModelData } from "../codegen/tables/CartridgeInsertionModel.sol";
import { TapeSubmissionModel, TapeSubmissionModelData } from "../codegen/tables/TapeSubmissionModel.sol";

import { ICartridgeInsertion } from "../interfaces/ICartridgeInsertion.sol";
import { ITapeSubmission } from "../interfaces/ITapeSubmission.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface WorldWithFuncs {
  function setNamespaceSystem(address, ResourceId) external;
}

interface RivesAsset {
  function setTapeParams(bytes32) external;
}

contract InputSystem is System {
  using WorldResourceIdInstance for ResourceId;
  error InputSystem__InvalidResource();
  error InputSystem__NotPermited();
  error InputSystem__InvalidParams();

  bytes4 constant insertCartridgeSelector = bytes4(0x5eab7461);
  bytes4 constant verifySelector = bytes4(0xdb690895);
  bytes4 constant registerVerificationSelector = bytes4(0xa98dfd7f);
  
  function _getSelector(bytes calldata payload) private pure returns (bytes4) {
    return bytes4(payload[:4]);
  }

  function _getCartridgeIdFromVerifyPayload(bytes calldata payload) private pure returns (bytes32) {
    return bytes32(payload[4:10]);
  }

  function prepareInput(address sender, uint256 value, bytes calldata payload) external payable returns (bool) {

    // get namespace system from db by dapp address
    // ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem");

    uint32 c = DebugCounter.get();
    DappMessagesDebug.set(c++, "prepareInput sender", abi.encode(sender));
    DappMessagesDebug.set(c++, "prepareInput tx.origin", abi.encode(tx.origin));
    DappMessagesDebug.set(c++, "prepareInput msg.sender", abi.encode(msg.sender));
    DappMessagesDebug.set(c++, "prepareInput _msgSender()", abi.encode(_msgSender()));
    DappMessagesDebug.set(c++, "prepareInput value", abi.encode(value));
    DappMessagesDebug.set(c++, "prepareInput msg.value", abi.encode(msg.value));
    DappMessagesDebug.set(c++, "prepareInput _msgValue()", abi.encode(_msgValue()));

    bytes4 selector = _getSelector(payload);

    // Insert cartridge
    if (insertCartridgeSelector == selector) {
      // get cartridge insertion system and validate payload
        
      CartridgeInsertionModelData memory model = CartridgeInsertionModel.get();
      bytes32 cartridgeId = ICartridgeInsertion(model.modelAddress).
        validateCartridgeInsertion(sender,payload,model.config);

      // block duplicate
      if (CartridgeOwner.get(cartridgeId) != address(0))
        revert InputSystem__InvalidParams();

      // DappMessagesDebug.set(c++, "insert cartridgeId", abi.encode(cartridgeId));
      CartridgeOwner.set(cartridgeId, sender);
      
    } else if (verifySelector == selector ||
        registerVerificationSelector == selector) {
      // get tape submission system and validate payload
      bytes32 cartridgeId = _getCartridgeIdFromVerifyPayload(payload);

      TapeSubmissionModelData memory model =
        TapeSubmissionModel.get(cartridgeId);
      // DappMessagesDebug.set(c++, "verify cartridgeId", abi.encode(cartridgeId));
      
      if (value > 0) {
        DappMessagesDebug.set(c++, "verifySelector namespace core balance", abi.encode(Balances.get(WorldResourceIdLib.encodeNamespace(bytes14("core")))));
        IWorld(_world()).transferBalanceToAddress(
          WorldResourceIdLib.encodeNamespace(bytes14("core")), model.modelAddress, value);
        DappMessagesDebug.set(c++, "verifySelector modelAddress balance", abi.encode(model.modelAddress.balance));
      }

      (, bytes memory data) = model.modelAddress.call(abi.encodeWithSignature("test()"));
      DappMessagesDebug.set(c++, "verifySelector modelAddress test", data);
    
      bytes32 tapeId = ITapeSubmission(model.modelAddress).
        validateTapeSubmission(sender,value,cartridgeId,payload,model.config);

      // bytes memory data = WorldContextProviderLib.delegatecallWithContextOrRevert(
      //   sender,
      //   _msgValue(),
      //   model.modelAddress,
      //   abi.encodeWithSignature("validateTapeSubmission(address,bytes32,bytes,bytes)", 
      //     sender,cartridgeId,payload,model.config)
      // );
      // bytes32 tapeId = bytes32(data);

      // DappMessagesDebug.set(c++, "verify tapeId", abi.encode(tapeId));

      // block duplicate
      if (TapeCreator.get(tapeId) != address(0))
        revert InputSystem__InvalidParams();

      TapeCreator.set(tapeId, sender);

      if (!ITapeSubmission(model.modelAddress).prepareTapeSubmission(tapeId,model.config))
        revert InputSystem__NotPermited();
    }
 
    DebugCounter.set(c);

    return true;
  }

  function addInputToCartesiInputBox(bytes32 resourceId, bytes calldata _payload) external returns (bytes32) {
    address dapp = NamespaceDappAddress.get(resourceId);
    if (dapp == address(0)) revert InputSystem__InvalidResource();
    
    // debug to see event
    // uint32 c = DebugCounter.get();
    // DappMessagesDebug.set(c++, "addInputToCartesiInputBox", abi.encode(dapp,_payload));
    // DebugCounter.set(c);

    // return 0x0;
    bytes memory returnData = IWorld(_world()).call(
      WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InputBoxSystem"),
      abi.encodeWithSignature("proxyAddInput(address,bytes)", dapp, _payload));

    return bytes32(returnData);
  }



}
