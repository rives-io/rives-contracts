// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ROOT_NAMESPACE, RESOURCE_NAMESPACE } from "@latticexyz/world/src/constants.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import {  DappAddressNamespace, NamespaceDappAddress, CartridgeInsertionModel,
          InputBoxAddress, CartridgeAssetAddress, TapeAssetAddress } from "../src/codegen/index.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { WorldRegistrationSystem } from "@latticexyz/world/src/modules/init/implementations/WorldRegistrationSystem.sol";

import { ICartesiDApp } from "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";
 
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { FreeCartridgeInsertion as CartridgeInsertion } from "../src/models/FreeCartridgeInsertion.sol";
import { FeeTapeSubmission } from "../src/models/FeeTapeSubmission.sol";
import { FreeTapeSubmission } from "../src/models/FreeTapeSubmission.sol";
import { OwnershipTapeSubmission } from "../src/models/OwnershipTapeSubmission.sol";

interface TapeSubmissionWithWorld {
  function worldAddress() view external returns (address);
  function setWorldAddress(address) external;
}


contract SetupResources is Script {
  address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
  bytes32 constant SALT = bytes32(0);

  function run() external {
    address dappAddress = vm.envAddress("DAPP_ADDRESS");
    address worldAddress = vm.envAddress("WORLD_ADDRESS");
    address inputBoxAddress = vm.envAddress("INPUT_BOX_ADDRESS");
    address cartridgeAssetAddress = vm.envAddress("CARTRIDGE_ASSET_ADDRESS");
    address tapeAssetAddress = vm.envAddress("TAPE_ASSET_ADDRESS");
    address operatorAddress = vm.envAddress("OPERATOR_ADDRESS");
    bytes memory cartridgeInsertionConfig = vm.envBytes("CARTRIDGE_INSERTION_CONFIG");

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
    console.logAddress(CartridgeAssetAddress.get());
    if (CartridgeAssetAddress.get() != cartridgeAssetAddress){
      console.logString("Didn't match, updating cartridge asset address to:");
      console.logAddress(cartridgeAssetAddress);
      IWorld(worldAddress).core__setCartridgeAssetAddress(cartridgeAssetAddress);
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

    // cartridge Insertion 
    bytes memory cartridgeInsertionCode = abi.encodePacked(type(CartridgeInsertion).creationCode);
    address cartridgeInsertionAddress = Create2.computeAddress(SALT, keccak256(cartridgeInsertionCode),DEPLOY_FACTORY);
    console.logString("Expected cartridgeInsertion");
    console.logAddress(cartridgeInsertionAddress);
    if (checkSize(cartridgeInsertionAddress) == 0) {
      CartridgeInsertion cartridgeInsertion = new CartridgeInsertion{salt: SALT}();
      console.logString("Deployed cartridgeInsertion");
      console.logAddress(address(cartridgeInsertion));
    } else {
      console.logString("Already deployed cartridgeInsertion");
    }

    if (!IWorld(worldAddress).core__getRegisteredModel(cartridgeInsertionAddress)) {
      console.logString("Model cartridgeInsertion not registered. Registering...");
      IWorld(worldAddress).core__setRegisteredModel(cartridgeInsertionAddress,true);
    } else {
      console.logString("Model cartridgeInsertion already registered");
    }
    
    // tape submission 
    bytes memory tapeSubmissionCode = abi.encodePacked(type(FreeTapeSubmission).creationCode);
    address tapeSubmissionAddress = Create2.computeAddress(SALT, keccak256(tapeSubmissionCode),DEPLOY_FACTORY);
    console.logString("Expected Free tapeSubmission");
    console.logAddress(tapeSubmissionAddress);
    if (checkSize(tapeSubmissionAddress) == 0) {
      FreeTapeSubmission tapeSubmission = new FreeTapeSubmission{salt: SALT}();
      console.logString("Deployed Free tapeSubmission");
      console.logAddress(address(tapeSubmission));
    } else {
      console.logString("Already deployed Free tapeSubmission");
    }
    
    if (!IWorld(worldAddress).core__getRegisteredModel(tapeSubmissionAddress)) {
      console.logString("Model Free tapeSubmission not registered. Registering...");
      IWorld(worldAddress).core__setRegisteredModel(tapeSubmissionAddress,true);
    } else {
      console.logString("Model Free tapeSubmission already registered");
    }

    tapeSubmissionCode = abi.encodePacked(type(OwnershipTapeSubmission).creationCode,abi.encode(operatorAddress));
    tapeSubmissionAddress = Create2.computeAddress(SALT, keccak256(tapeSubmissionCode),DEPLOY_FACTORY);
    console.logString("Expected Ownership tapeSubmission");
    console.logAddress(tapeSubmissionAddress);
    if (checkSize(tapeSubmissionAddress) == 0) {
      OwnershipTapeSubmission tapeSubmission = new OwnershipTapeSubmission{salt: SALT}(operatorAddress);
      console.logString("Deployed Ownership tapeSubmission");
      console.logAddress(address(tapeSubmission));
    } else {
      console.logString("Already deployed Ownership tapeSubmission");
    }
    
    if (TapeSubmissionWithWorld(tapeSubmissionAddress).worldAddress() != worldAddress) {
      console.logString("Setting the worldAddress of Ownership tapeSubmission from - to");
      console.logAddress(TapeSubmissionWithWorld(tapeSubmissionAddress).worldAddress());
      console.logAddress(worldAddress);
      TapeSubmissionWithWorld(tapeSubmissionAddress).setWorldAddress(worldAddress);
    }

    if (!IWorld(worldAddress).core__getRegisteredModel(tapeSubmissionAddress)) {
      console.logString("Model Ownership tapeSubmission not registered. Registering...");
      IWorld(worldAddress).core__setRegisteredModel(tapeSubmissionAddress,true);
    } else {
      console.logString("Model Ownership tapeSubmission already registered");
    }


    tapeSubmissionCode = abi.encodePacked(type(FeeTapeSubmission).creationCode,abi.encode(operatorAddress));
    tapeSubmissionAddress = Create2.computeAddress(SALT, keccak256(tapeSubmissionCode),DEPLOY_FACTORY);
    console.logString("Expected Fee tapeSubmission");
    console.logAddress(tapeSubmissionAddress);
    if (checkSize(tapeSubmissionAddress) == 0) {
      FeeTapeSubmission tapeSubmission = new FeeTapeSubmission{salt: SALT}(operatorAddress);
      console.logString("Deployed Fee tapeSubmission");
      console.logAddress(address(tapeSubmission));
    } else {
      console.logString("Already deployed Fee tapeSubmission");
    }
    
    if (TapeSubmissionWithWorld(tapeSubmissionAddress).worldAddress() != worldAddress) {
      console.logString("Setting the worldAddress of Fee tapeSubmission from - to");
      console.logAddress(TapeSubmissionWithWorld(tapeSubmissionAddress).worldAddress());
      console.logAddress(worldAddress);
      TapeSubmissionWithWorld(tapeSubmissionAddress).setWorldAddress(worldAddress);
    }
    if (!IWorld(worldAddress).core__getRegisteredModel(tapeSubmissionAddress)) {
      console.logString("Model Fee tapeSubmission not registered. Registering...");
      IWorld(worldAddress).core__setRegisteredModel(tapeSubmissionAddress,true);
    } else {
      console.logString("Model Fee tapeSubmission already registered");
    }

    // setup cartridge insertion model
    console.logString("Current Cartridge Insertion Model is:");
    console.logAddress(CartridgeInsertionModel.getModelAddress());
    if (CartridgeInsertionModel.getModelAddress() != cartridgeInsertionAddress ||
        keccak256(CartridgeInsertionModel.getConfig()) != keccak256(cartridgeInsertionConfig)){
      console.logString("Didn't match, updating Cartridge Insertion Model to:");
      console.logAddress(cartridgeInsertionAddress);
      IWorld(worldAddress).core__setCartridgeInsertionModel(cartridgeInsertionAddress,cartridgeInsertionConfig);
    }

    vm.stopBroadcast();
  }

  function checkSize(address addr) public view returns(uint extSize) {
      assembly {
          extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
      }
  }
    
}
