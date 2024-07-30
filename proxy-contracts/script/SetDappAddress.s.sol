// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ROOT_NAMESPACE, RESOURCE_NAMESPACE } from "@latticexyz/world/src/constants.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { DappAddressNamespace, NamespaceDappAddress } from "../src/codegen/index.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/init/implementations/WorldRegistrationSystem.sol";
 
import { IWorld } from "../src/codegen/world/IWorld.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { ICartesiDApp } from "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";

contract SetDappAddress is Script {
  function run() external {
    address dappAddress = vm.envAddress("DAPP_ADDRESS");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
 
    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    ResourceId coreSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "CoreSystem");

    console.logString("Current dapp address is:");
    console.logAddress(NamespaceDappAddress.get(ResourceId.unwrap(coreSystem)));
    console.logString("And Core system Dapp is:");
    console.logBytes32(DappAddressNamespace.get(dappAddress));
    if (NamespaceDappAddress.get(ResourceId.unwrap(coreSystem)) != dappAddress || 
        DappAddressNamespace.get(dappAddress) != ResourceId.unwrap(coreSystem)){
      console.logString("Didn't match, updating core system dapp address to:");
      console.logAddress(dappAddress);
      IWorld(worldAddress).core__setDappAddress(dappAddress);
    }


    // console.logString("tx.origin:");
    // console.logAddress(tx.origin);
    // console.logString("msg.sender:");
    // console.logAddress(msg.sender);
    // ResourceId coreNamespace = WorldResourceIdLib.encode(RESOURCE_NAMESPACE, "core");
    // console.logString("coreNamespace:");
    // console.logBytes32(coreNamespace);
    // IWorld(worldAddress).transferOwnership(coreNamespace, tx.origin);

    // console.logString("Owner:");
    // // console.logAddress(CartesiDApp(dappAddress).owner());
    // (bool success, bytes memory data) = dappAddress.staticcall(abi.encodeWithSignature("owner()"));
    // console.logBool(success);
    // console.logBytes(data);
    // console.logString("hash:");
    // (success, data) = dappAddress.staticcall(abi.encodeWithSignature("getTemplateHash()"));
    // console.logBool(success);
    // console.logBytes(data);
    // console.logBytes32(ICartesiDApp(dappAddress).getTemplateHash());

    console.logString("Done");

    vm.stopBroadcast();
  }
}
