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

import { CartridgeOwner, TapeCreator, NamespaceDappAddress } from "../codegen/index.sol";

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

      CartridgeOwner.set(cartridgeId, sender);
      
    } else if (verifySelector == selector ||
        registerVerificationSelector == selector) {
      // get tape submission system and validate payload
      bytes32 cartridgeId = _getCartridgeIdFromVerifyPayload(payload);

      TapeSubmissionModelData memory model =
        TapeSubmissionModel.get(cartridgeId);
      
      if (value > 0) {
        IWorld(_world()).transferBalanceToAddress(
          WorldResourceIdLib.encodeNamespace(bytes14("core")), model.modelAddress, value);
      }

      (, bytes memory data) = model.modelAddress.call(abi.encodeWithSignature("test()"));
    
      bytes32 tapeId = ITapeSubmission(model.modelAddress).
        validateTapeSubmission(sender,value,cartridgeId,payload,model.config);

      // block duplicate
      if (TapeCreator.get(tapeId) != address(0))
        revert InputSystem__InvalidParams();

      TapeCreator.set(tapeId, sender);

      if (!ITapeSubmission(model.modelAddress).prepareTapeSubmission(tapeId,model.config))
        revert InputSystem__NotPermited();
    }
 
    return true;
  }

  function addInputToCartesiInputBox(bytes32 resourceId, bytes calldata _payload) external returns (bytes32) {
    address dapp = NamespaceDappAddress.get(resourceId);
    if (dapp == address(0)) revert InputSystem__InvalidResource();
    
    // return 0x0;
    bytes memory returnData = IWorld(_world()).call(
      WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InputBoxSystem"),
      abi.encodeWithSignature("proxyAddInput(address,bytes)", dapp, _payload));

    return bytes32(returnData);
  }



}
