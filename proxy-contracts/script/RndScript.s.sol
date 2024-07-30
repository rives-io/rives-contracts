// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ROOT_NAMESPACE } from "@latticexyz/world/src/constants.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/init/implementations/WorldRegistrationSystem.sol";
 
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract RndScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
 
    WorldRegistrationSystem world = WorldRegistrationSystem(worldAddress);

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld(worldAddress).core__setInputBoxAddress(0x59b22D57D4f067708AB0c00552767405926dc768);

    ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem");
    console.logString("==== DEBUG ==== coreDappSystem id: ");
    console.logBytes(abi.encodePacked(coreDappSystem));
    console.logString("coreSystem id: ");
    console.logBytes(abi.encodePacked(WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem")));
    console.logString("InputBoxSystem id: ");
    console.logBytes(abi.encodePacked(WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InputBoxSystem")));

    bytes4 selector = world.registerRootFunctionSelector(coreDappSystem, "addInput(address,bytes)","addInput(address,bytes)");
    console.logBytes(abi.encodePacked(selector));
    selector = world.registerRootFunctionSelector(
      coreDappSystem,
      "validateNotice(bytes32,bytes,(uint64,uint64,bytes32,bytes32,bytes32,bytes32,bytes32[],bytes32[])[])",
      "validateNotice(bytes32,bytes,(uint64,uint64,bytes32,bytes32,bytes32,bytes32,bytes32[],bytes32[])[])");
    console.logBytes(abi.encodePacked(selector));
    selector = world.registerRootFunctionSelector(coreDappSystem, "setNamespaceSystem(address,bytes32)","setNamespaceSystem(address,bytes32)");
    console.logBytes(abi.encodePacked(selector));
    selector = world.registerRootFunctionSelector(coreDappSystem, "addSystemSubscription(bytes32,bytes32)","addSystemSubscription(bytes32,bytes32)");
    console.logBytes(abi.encodePacked(selector));
    selector = world.registerRootFunctionSelector(coreDappSystem, "removeSystemSubscription(bytes32,bytes32)","removeSystemSubscription(bytes32,bytes32)");
    console.logBytes(abi.encodePacked(selector));

    IWorld(worldAddress).core__setDappAddress(0xb35D7fec2ceE073F027fd6cf532628362976233A);

    vm.stopBroadcast();
  }
}
