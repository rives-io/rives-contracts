// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ROOT_NAMESPACE, RESOURCE_NAMESPACE } from "@latticexyz/world/src/constants.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { DappAddressNamespace, NamespaceDappAddress, InputBoxAddress, CatridgeAssetAddress, TapeAssetAddress } from "../src/codegen/index.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/init/implementations/WorldRegistrationSystem.sol";
 
import { IWorld } from "../src/codegen/world/IWorld.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import { ICartesiDApp } from "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";

contract SetupResources is Script {
  function run() external {
    address dappAddress = vm.envAddress("DAPP_ADDRESS");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    address inputBoxAddress = 0x59b22D57D4f067708AB0c00552767405926dc768;
    address cartridgeAssetAddress = 0x1FB41930ec1A52B3C5467EbAe54af4091e8D0039;
    address tapeAssetAddress = 0x137b837544b13B99d49ad8eE6a3488139F487920;

    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
 
    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    console.logString("Current inputBox address is:");
    console.logAddress(InputBoxAddress.get());
    if (InputBoxAddress.get() != inputBoxAddress){
      console.logString("Didn't match, updating inputBox address to:");
      console.logAddress(inputBoxAddress);
      IWorld(worldAddress).core__setInputBoxAddress(inputBoxAddress);
    }
    
    console.logString("Current cartridge asset address is:");
    console.logAddress(CatridgeAssetAddress.get());
    if (CatridgeAssetAddress.get() != cartridgeAssetAddress){
      console.logString("Didn't match, updating cartridge asset address to:");
      console.logAddress(cartridgeAssetAddress);
      IWorld(worldAddress).core__setCatridgeAssetAddress(cartridgeAssetAddress);
    }
    
    console.logString("Current tape asset address is:");
    console.logAddress(TapeAssetAddress.get());
    if (TapeAssetAddress.get() != tapeAssetAddress){
      console.logString("Didn't match, updating tape asset address to:");
      console.logAddress(tapeAssetAddress);
      IWorld(worldAddress).core__setTapeAssetAddress(tapeAssetAddress);
    }
    
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
