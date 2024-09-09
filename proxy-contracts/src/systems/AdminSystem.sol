// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


import { InputBoxAddress, CartridgeAssetAddress, TapeAssetAddress, 
          CartridgeInsertionModel, RegisteredModel } from "../codegen/index.sol";
import "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";

import { ICartridgeInsertion } from "../interfaces/ICartridgeInsertion.sol";

contract AdminSystem is System {
  using WorldResourceIdInstance for ResourceId;
  error AdminSystem__InvalidOwner();
  error AdminSystem__InvalidParams();
  error AdminSystem__InvalidModel();
  
  function setInputBoxAddress(address _inputBox) public {
    // set dapp address
    InputBoxAddress.set(_inputBox);
  }

  function setCartridgeAssetAddress(address _cartridgeAsset) public {
    // set cartridge asset
    CartridgeAssetAddress.set(_cartridgeAsset);
  }

  function setTapeAssetAddress(address _tapeAsset) public {
    // set tape asset
    TapeAssetAddress.set(_tapeAsset);
  }

  function setRegisteredModel(address modelAddress, bool active) public {
    // set registered models
    RegisteredModel.set(modelAddress, active);
  }

  function setCartridgeInsertionModel(address modelAddress, bytes calldata config) public {
    // Check if model is registered
    if (!RegisteredModel.get(modelAddress)) revert AdminSystem__InvalidModel();

    // validate config
    if (!ICartridgeInsertion(modelAddress).validateConfig(config))
      revert AdminSystem__InvalidParams();

    CartridgeInsertionModel.set(modelAddress,config);
  }

}
