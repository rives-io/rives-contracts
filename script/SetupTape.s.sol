// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import { Script,console } from "forge-std/src/Script.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";


import { TapeFixedFeeVanguard3 } from "../src/TapeFixedFeeVanguard3.sol";
import { TapeModelVanguard3 } from "../src/TapeModelVanguard3.sol";
import { OwnershipModelVanguard3 } from "../src/OwnershipModelVanguard3.sol";
import { BondingCurveModelVanguard3 } from "../src/BondingCurveModelVanguard3.sol";
import { TapeBondUtils } from "../src/TapeBondUtils.sol";
import { Tape } from "../src/Tape.sol";


contract SECP256K1_ORDERetupTape is Script {
    address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 constant SALT = bytes32(0);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address dappAddress = vm.envAddress("DAPP_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);


        // Currency 
        // address currencyAddress = address(0);

        // Tape Fee Model 
        bytes memory feeModelCode = abi.encodePacked(type(TapeFixedFeeVanguard3).creationCode);        
        
        // Tape Model 
        bytes memory tapeModelCode = abi.encodePacked(type(TapeModelVanguard3).creationCode);
        
        // Ownership Model 
        bytes memory ownershipModelCode = abi.encodePacked(type(OwnershipModelVanguard3).creationCode);
        
        // Bonding Curve Model 
        bytes memory bcModelCode = abi.encodePacked(type(BondingCurveModelVanguard3).creationCode);
        
        // Tape Bond Utils
        bytes memory tapeBondUtilsCode = abi.encodePacked(type(TapeBondUtils).creationCode);

        // Tape
        bytes memory tapeCode = abi.encodePacked(type(Tape).creationCode,
            abi.encode(
                Create2.computeAddress(SALT, keccak256(tapeBondUtilsCode),DEPLOY_FACTORY),
                100 // max steps
            )
        );
        Tape tape = Tape(Create2.computeAddress(SALT, keccak256(tapeCode),DEPLOY_FACTORY));

        console.logString("Updating bonding curve params");
        // console.logAddress(msg.sender);
        // console.logAddress(tx.origin);
        // console.logAddress(tape.owner());
        uint128[] memory ranges =  new uint128[](3); //[1,5,1000];
        ranges[0] = 1;
        ranges[1] = 5;
        ranges[2] = 1000;
        uint128[] memory coefficients = new uint128[](3);//[uint128(1000000000000000),uint128(1000000000000000),uint128(2000000000000000)];
        coefficients[0] = 1000000000000000;
        coefficients[1] = 1000000000000000;
        coefficients[2] = 2000000000000000;
        tape.updateBondingCurveParams(
            // newCurrencyToken, newFeeModel, newTapeModel, newTapeOwnershipModelAddress, newTapeBondingCurveModelAddress, newMaxSupply, stepRangesMax, stepCoefficients
            address(0), //currencyAddress,
            Create2.computeAddress(SALT, keccak256(feeModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(tapeModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(ownershipModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(bcModelCode),DEPLOY_FACTORY),
            1000, // max supply
            ranges,
            coefficients
        );

        if (!tape.dappAddresses(dappAddress)) {
            console.logString("Adding dapp address");
            tape.addDapp(dappAddress);
        }

        console.logString("Setting uri");
        tape.setURI("https://vanguard.rives.io/tapes/{id}");

        vm.stopBroadcast();
    }
    
}

// # tape asset
// MAX_STEPS=100
// MAX_SUPPLY=1000
// RANGES="[1,5,1000]"
// # COEFS="[10000,1000,2000]"
// COEFS="[1000000000000000,1000000000000000,2000000000000000]"

// ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $TAPE_FEE_MODEL $TAPE_MODEL $OWNERSHIP_MODEL $BC_MODEL $TAPE_BOND_UTILS $MAX_SUPPLY $RANGES $COEFS"

