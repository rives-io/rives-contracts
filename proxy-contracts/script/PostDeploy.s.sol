// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ROOT_NAMESPACE, RESOURCE_NAMESPACE  } from "@latticexyz/world/src/constants.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/init/implementations/WorldRegistrationSystem.sol";
 
import { Systems } from "@latticexyz/world/src/codegen/index.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

contract PostDeploy is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
 
    WorldRegistrationSystem world = WorldRegistrationSystem(worldAddress);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem");
    console.logString("DappSystem id/address: ");
    console.logBytes(abi.encodePacked(coreDappSystem));
    console.logAddress(Systems.getSystem(coreDappSystem));
    console.logString("AdminSystem id/address: ");
    ResourceId systemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "AdminSystem");
    console.logBytes(abi.encodePacked(systemId));
    console.logAddress(Systems.getSystem(systemId));
    console.logString("InfoSystem id/address: ");
    systemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InfoSystem");
    console.logBytes(abi.encodePacked(systemId));
    console.logAddress(Systems.getSystem(systemId));
    console.logString("CoreSystem id/address: ");
    systemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem");
    console.logBytes(abi.encodePacked(systemId));
    console.logAddress(Systems.getSystem(systemId));
    console.logString("InputSystem id/address: ");
    systemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InputSystem");
    console.logBytes(abi.encodePacked(systemId));
    console.logAddress(Systems.getSystem(systemId));
    console.logString("InputBoxSystem id/address: ");
    systemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InputBoxSystem");
    console.logBytes(abi.encodePacked(systemId));
    console.logAddress(Systems.getSystem(systemId));

    world.registerRootFunctionSelector(coreDappSystem, "addInput(address,bytes)","addInput(address,bytes)");
    
    world.registerRootFunctionSelector(coreDappSystem, "setNamespaceSystem(address,bytes32)","setNamespaceSystem(address,bytes32)");
    
    ResourceId coreSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem");
    world.registerRootFunctionSelector(coreSystem, "setCartridgeOwner(bytes32)","setCartridgeOwner(bytes32)");

    world.registerRootFunctionSelector(coreSystem, "getCartridgeOwner(bytes32)","getCartridgeOwner(bytes32)");

    world.registerRootFunctionSelector(coreSystem, "getTapeCreator(bytes32)","getTapeCreator(bytes32)");
    
    world.registerRootFunctionSelector(coreSystem, "setCartridgeInsertionModel(address,bytes)","setCartridgeInsertionModel(address,bytes)");
    
    world.registerRootFunctionSelector(coreSystem, "getCartridgeInsertionModel()","getCartridgeInsertionModel()");

    world.registerRootFunctionSelector(coreSystem, "setTapeSubmissionModel(bytes32,address,bytes)","setTapeSubmissionModel(bytes32,address,bytes)");

    world.registerRootFunctionSelector(coreSystem, "getTapeSubmissionModel(bytes32)","getTapeSubmissionModel(bytes32)");

    world.registerRootFunctionSelector(coreSystem, "getTapeSubmissionModelAddress(bytes32)","getTapeSubmissionModelAddress(bytes32)");

    world.registerRootFunctionSelector(coreSystem, "getRegisteredModel(address)","getRegisteredModel(address)");

    vm.stopBroadcast();
  }
}
