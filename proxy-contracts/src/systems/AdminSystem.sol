// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { SystemCallData } from "@latticexyz/world/src/modules/init/types.sol";
 
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


import { InputBoxAddress } from "../codegen/index.sol";
import "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";

contract AdminSystem is System {
  
  function setInputBoxAddress(address _inputBox) public {
    // set dapp address
    InputBoxAddress.set(_inputBox);
  }

}
