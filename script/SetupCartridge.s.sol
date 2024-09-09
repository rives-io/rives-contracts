// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import { Script,console } from "forge-std/src/Script.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";


import { CartridgeMixedFeeVanguard4 as CartridgeFeeModel } from "../src/CartridgeMixedFeeVanguard4.sol";
import { CartridgeModelVanguard4 as CartridgeModel} from "../src/CartridgeModelVanguard4.sol";
import { CartridgeOwnershipModelWithProxy as OwnershipModel } from "../src/CartridgeOwnershipModelWithProxy.sol";
import { BondingCurveModelVanguard3 as BondingCurveModel } from "../src/BondingCurveModelVanguard3.sol";
import { CartridgeBondUtils } from "../src/CartridgeBondUtils.sol";
import { Cartridge } from "../src/Cartridge.sol";


contract SetupCartridge is Script {
    address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 constant SALT = bytes32(0);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address dappAddress = vm.envAddress("DAPP_ADDRESS");
        address operatorAddress = vm.envAddress("OPERATOR_ADDRESS");
        address worldAddress = vm.envAddress("WORLD_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        console.logString("Setup Cartridge Contracts");

        // Currency 
        address currencyAddress = address(0);

        // Cartridge Fee Model 
        bytes memory feeModelCode = abi.encodePacked(type(CartridgeFeeModel).creationCode);        
        
        // Cartridge Model 
        bytes memory cartridgeModelCode = abi.encodePacked(type(CartridgeModel).creationCode);
        
        // Ownership Model 
        bytes memory ownershipModelCode = abi.encodePacked(type(OwnershipModel).creationCode,abi.encode(operatorAddress));
        address ownershipModelAddress = Create2.computeAddress(SALT, keccak256(ownershipModelCode),DEPLOY_FACTORY);
        
        // Bonding Curve Model 
        bytes memory bcModelCode = abi.encodePacked(type(BondingCurveModel).creationCode);
        
        // Cartridge Bond Utils
        bytes memory cartridgeBondUtilsCode = abi.encodePacked(type(CartridgeBondUtils).creationCode);

        // Cartridge
        bytes memory cartridgeCode = abi.encodePacked(type(Cartridge).creationCode,
            abi.encode(
                operatorAddress,
                Create2.computeAddress(SALT, keccak256(cartridgeBondUtilsCode),DEPLOY_FACTORY),
                100 // max steps
            )
        );
        Cartridge cartridge = Cartridge(Create2.computeAddress(SALT, keccak256(cartridgeCode),DEPLOY_FACTORY));

        console.logString("Updating bonding curve params");

        uint256[] memory ranges =  new uint256[](2); //[1,5,1000];
        ranges[0] = 1;
        ranges[1] = 10000;
        uint256[] memory coefficients = new uint256[](2);//[uint256(1000000000000000),uint256(1000000000000000),uint256(2000000000000000)];
        coefficients[0] = 10000000000000000;
        coefficients[1] = 1000000000000000;
        cartridge.updateBondingCurveParams(
            currencyAddress,
            Create2.computeAddress(SALT, keccak256(feeModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(cartridgeModelCode),DEPLOY_FACTORY),
            ownershipModelAddress,
            Create2.computeAddress(SALT, keccak256(bcModelCode),DEPLOY_FACTORY),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, // max supply
            50, // fee config - feeProportionPerK
            ranges,
            coefficients
        );

        if (!cartridge.dappAddresses(dappAddress)) {
            console.logString("Adding dapp address");
            cartridge.setDapp(dappAddress,true);
        }

        console.logString("Setting uri");
        cartridge.setURI("https://vanguard.rives.io/cartridges/{id}");

        if (OwnershipModel(ownershipModelAddress).owner() != operatorAddress && OwnershipModel(ownershipModelAddress).owner() == tx.origin) {
            console.logString("Transfering ownership of ownership model from - to");
            console.logAddress(OwnershipModel(ownershipModelAddress).owner());
            console.logAddress(operatorAddress);
            OwnershipModel(ownershipModelAddress).transferOwnership(operatorAddress);
        }

        // only on vanguard 4
        if (OwnershipModel(ownershipModelAddress).worldAddress() != worldAddress) {
            console.logString("Setting the worldAddress of ownership model from - to");
            console.logAddress(OwnershipModel(ownershipModelAddress).worldAddress());
            console.logAddress(worldAddress);
            OwnershipModel(ownershipModelAddress).setWorldAddress(worldAddress);
        }

        if (cartridge.owner() != operatorAddress && cartridge.owner() == tx.origin) {
            console.logString("Transfering ownership of cartridge from - to");
            console.logAddress(cartridge.owner());
            console.logAddress(operatorAddress);
            cartridge.transferOwnership(operatorAddress);
        }
        
        vm.stopBroadcast();
    }
    
}

// # cartridge asset
// MAX_STEPS=100
// MAX_SUPPLY=1000
// RANGES="[1,5,1000]"
// # COEFS="[10000,1000,2000]"
// COEFS="[1000000000000000,1000000000000000,2000000000000000]"

// ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $TAPE_FEE_MODEL $TAPE_MODEL $OWNERSHIP_MODEL $BC_MODEL $TAPE_BOND_UTILS $MAX_SUPPLY $RANGES $COEFS"

