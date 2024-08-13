// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { SystemCallData } from "@latticexyz/world/src/modules/init/types.sol";
 
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


import { InputBoxAddress, CatridgeAssetAddress, TapeAssetAddress } from "../codegen/index.sol";
import "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";

contract AdminSystem is System {
  using WorldResourceIdInstance for ResourceId;
  error AdminSystem__InvalidOwner();
  
  modifier _checkOwner() {
    ResourceId adminSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "AdminSystem");
    if (NamespaceOwner.get(adminSystem.getNamespaceId()) != tx.origin) revert AdminSystem__InvalidOwner();
    _;
  }

  function setInputBoxAddress(address _inputBox) public _checkOwner() {
    // set dapp address
    InputBoxAddress.set(_inputBox);
  }

  function setCatridgeAssetAddress(address _cartridgeAsset) public _checkOwner() {
    // set dapp address
    CatridgeAssetAddress.set(_cartridgeAsset);
  }

  function setTapeAssetAddress(address _tapeAsset) public _checkOwner() {
    // set dapp address
    TapeAssetAddress.set(_tapeAsset);
  }

}
