// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { SystemCallData } from "@latticexyz/world/src/modules/init/types.sol";
 
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface WorldWithFuncs {
  function setNamespaceSystem(address, ResourceId) external;
}

contract CoreSystem is System {
  
  function prepareInput(bytes calldata ) public pure returns (bool) {

    // get namespace system from db by dapp address
    // ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem");

    // TODO: perform any checks here, such as check for cartridge license
 
    // bool whether to send to input own box
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
