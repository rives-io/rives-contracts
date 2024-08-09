// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ROOT_NAMESPACE, RESOURCE_NAMESPACE  } from "@latticexyz/world/src/constants.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/init/implementations/WorldRegistrationSystem.sol";
 
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

    IWorld(worldAddress).core__setInputBoxAddress(0x59b22D57D4f067708AB0c00552767405926dc768);
    IWorld(worldAddress).core__setCatridgeAssetAddress(0x6c1e41F47174DeB54c7B64Acaf1A465BC083DcAe);

    ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem");
    console.logString("==== DEBUG ==== coreDappSystem id: ");
    console.logBytes(abi.encodePacked(coreDappSystem));
    console.logString("coreSystem id: ");
    console.logBytes(abi.encodePacked(WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem")));
    console.logString("InputBoxSystem id: ");
    console.logBytes(abi.encodePacked(WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InputBoxSystem")));

    bytes4 selector = world.registerRootFunctionSelector(coreDappSystem, "addInput(address,bytes)","addInput(address,bytes)");
    console.logBytes(abi.encodePacked(selector));
    
    selector = world.registerRootFunctionSelector(coreDappSystem, "setNamespaceSystem(address,bytes32)","setNamespaceSystem(address,bytes32)");
    console.logBytes(abi.encodePacked(selector));
    
    selector = world.registerRootFunctionSelector(WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem"), "getCartridgeCreator(bytes32)","getCartridgeCreator(bytes32)");
    console.logBytes(abi.encodePacked(selector));
    
    console.logString("tx.origin:");
    console.logAddress(tx.origin);
    console.logString("msg.sender:");
    console.logAddress(msg.sender);
    ResourceId coreNamespace = WorldResourceIdLib.encodeNamespace(bytes14("core"));
    console.logString("ROOT_NAMESPACE:");
    console.logBytes32(ROOT_NAMESPACE);
    console.logString("coreNamespace:");
    console.logBytes32(ResourceId.unwrap(coreNamespace));
    // IWorld(worldAddress).transferOwnership(coreNamespace, tx.origin);

    vm.stopBroadcast();
  }
}
