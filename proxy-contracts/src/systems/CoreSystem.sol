// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { SystemCallData } from "@latticexyz/world/src/modules/init/types.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";

import { Systems } from "@latticexyz/world/src/codegen/index.sol";

import { CartridgeOwner, TapeCreator, RegisteredModel } from "../codegen/index.sol";

import { CartridgeInsertionModel, CartridgeInsertionModelData } from "../codegen/tables/CartridgeInsertionModel.sol";
import { TapeSubmissionModel, TapeSubmissionModelData } from "../codegen/tables/TapeSubmissionModel.sol";

import { ITapeSubmission } from "../interfaces/ITapeSubmission.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface WorldWithFuncs {
  function setNamespaceSystem(address, ResourceId) external;
}

interface RivesAsset {
  function setTapeParams(bytes32) external;
}

contract CoreSystem is System {
  using WorldResourceIdInstance for ResourceId;
  error CoreSystem__NotPermited();
  error CoreSystem__InvalidParams();
  error CoreSystem__InvalidModel();

  function getCartridgeOwner(bytes32 cartridgeId) public view returns (address) {
    return CartridgeOwner.get(cartridgeId);
  }

  function setCartridgeOwner(bytes32 cartridgeId, address newOwner) public {
    if (_msgSender() != CartridgeOwner.get(cartridgeId)) revert CoreSystem__NotPermited();
    CartridgeOwner.set(cartridgeId,newOwner);
  }

  function getTapeCreator(bytes32 tapeId) public view returns (address) {
    return TapeCreator.get(tapeId);
  }

  function getCartridgeInsertionModel() public view returns (CartridgeInsertionModelData memory) {
    return CartridgeInsertionModel.get();
  }

  function setTapeSubmissionModel(bytes32 cartridgeId,address modelAddress, bytes calldata config) public {
    ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem");
    if (_msgSender() != CartridgeOwner.get(cartridgeId) &&
      NamespaceOwner.get(coreDappSystem.getNamespaceId()) != _msgSender()) revert CoreSystem__NotPermited();
    
    // Check if model is registered
    if (! RegisteredModel.get(modelAddress)) revert CoreSystem__InvalidModel();

    // update TapeSubmissionModel because model could check
    TapeSubmissionModel.set(cartridgeId, modelAddress, config);

    // validate config
    if (!ITapeSubmission(modelAddress).validateConfig(cartridgeId,config))
      revert CoreSystem__NotPermited();
  }

  function getTapeSubmissionModel(bytes32 cartridgeId) public view returns (TapeSubmissionModelData memory) {
    return TapeSubmissionModel.get(cartridgeId);
  }

  function getCartridgeIdFromTapeId(bytes calldata payload) public pure returns (bytes32) {
    return bytes32(payload[:6]);
  }

  function getTapeSubmissionModelAddress(bytes32 tapeOrCartridgeId) public view returns (address) {
    TapeSubmissionModelData memory model = TapeSubmissionModel.get(this.getCartridgeIdFromTapeId(abi.encodePacked(tapeOrCartridgeId)));
    return model.modelAddress;
  }

  function getSystem(bytes16 systemName) public view returns (address) {
    return Systems.getSystem(WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", systemName));
  }

  function getRegisteredModel(address modelAddress) public view returns (bool) {
    return RegisteredModel.get(modelAddress);
  }

  function setDappAddress(address _dapp) public {
    // call the update set namespace for a dapp
    WorldContextProviderLib.delegatecallWithContextOrRevert(
      _msgSender(),
      _msgValue(),
      Systems.getSystem(WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem")),
      abi.encodeWithSignature("setNamespaceSystem(address,bytes32)", 
        _dapp, 
        WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem"))
    );
  }

}
