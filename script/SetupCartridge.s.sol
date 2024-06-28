// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import { Script,console } from "forge-std/src/Script.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";


import { CartridgeFixedFeeVanguard3 } from "../src/CartridgeFixedFeeVanguard3.sol";
import { CartridgeModelVanguard3 } from "../src/CartridgeModelVanguard3.sol";
import { OwnershipModelVanguard3 } from "../src/OwnershipModelVanguard3.sol";
import { BondingCurveModelVanguard3 } from "../src/BondingCurveModelVanguard3.sol";
import { CartridgeBondUtils } from "../src/CartridgeBondUtils.sol";
import { Cartridge } from "../src/Cartridge.sol";


contract SECP256K1_ORDERetupCartridge is Script {
    address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 constant SALT = bytes32(0);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address dappAddress = vm.envAddress("DAPP_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);


        // Currency 
        // address currencyAddress = address(0);

        // Cartridge Fee Model 
        bytes memory feeModelCode = abi.encodePacked(type(CartridgeFixedFeeVanguard3).creationCode);        
        
        // Cartridge Model 
        bytes memory cartridgeModelCode = abi.encodePacked(type(CartridgeModelVanguard3).creationCode);
        
        // Ownership Model 
        bytes memory ownershipModelCode = abi.encodePacked(type(OwnershipModelVanguard3).creationCode);
        
        // Bonding Curve Model 
        bytes memory bcModelCode = abi.encodePacked(type(BondingCurveModelVanguard3).creationCode);
        
        // Cartridge Bond Utils
        bytes memory cartridgeBondUtilsCode = abi.encodePacked(type(CartridgeBondUtils).creationCode);

        // Cartridge
        bytes memory cartridgeCode = abi.encodePacked(type(Cartridge).creationCode,
            abi.encode(
                Create2.computeAddress(SALT, keccak256(cartridgeBondUtilsCode),DEPLOY_FACTORY),
                100 // max steps
            )
        );
        Cartridge cartridge = Cartridge(Create2.computeAddress(SALT, keccak256(cartridgeCode),DEPLOY_FACTORY));

        console.logString("Updating bonding curve params");
        // console.logAddress(msg.sender);
        // console.logAddress(tx.origin);
        // console.logAddress(cartridge.owner());
        uint128[] memory ranges =  new uint128[](3); //[1,5,1000];
        ranges[0] = 1;
        ranges[1] = 5;
        ranges[2] = 1000;
        uint128[] memory coefficients = new uint128[](3);//[uint128(1000000000000000),uint128(1000000000000000),uint128(2000000000000000)];
        coefficients[0] = 5000000000000000;
        coefficients[1] = 1000000000000000;
        coefficients[2] = 2000000000000000;
        cartridge.updateBondingCurveParams(
            // newCurrencyToken, newFeeModel, newCartridgeModel, newCartridgeOwnershipModelAddress, newCartridgeBondingCurveModelAddress, newMaxSupply, stepRangesMax, stepCoefficients
            address(0), //currencyAddress,
            Create2.computeAddress(SALT, keccak256(feeModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(cartridgeModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(ownershipModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(bcModelCode),DEPLOY_FACTORY),
            1000, // max supply
            ranges,
            coefficients
        );

        if (!cartridge.dappAddresses(dappAddress)) {
            console.logString("Adding dapp address");
            cartridge.addDapp(dappAddress);
        }

        console.logString("Setting uri");
        cartridge.setURI("https://vanguard.rives.io/cartridges/{id}");

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

