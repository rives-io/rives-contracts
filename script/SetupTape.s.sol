// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import { Script,console } from "forge-std/src/Script.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";


import { TapeProportionalFeeVanguard3v2 as TapeFeeModel } from "../src/TapeProportionalFeeVanguard3v2.sol";
import { TapeModelVanguard4 as TapeModel} from "../src/TapeModelVanguard4.sol";
import { TapeOwnershipModelVanguard4 as OwnershipModel } from "../src/TapeOwnershipModelVanguard4.sol";
import { BondingCurveModelVanguard3 as BondingCurveModel } from "../src/BondingCurveModelVanguard3.sol";
import { TapeBondUtils } from "../src/TapeBondUtils.sol";
import { Tape } from "../src/Tape.sol";


contract SECP256K1_ORDERetupTape is Script {
    address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 constant SALT = bytes32(0);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address dappAddress = vm.envAddress("DAPP_ADDRESS");
        address operatorAddress = vm.envAddress("OPERATOR_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);


        // Currency 
        // address currencyAddress = address(0);

        // Tape Fee Model 
        bytes memory feeModelCode = abi.encodePacked(type(TapeFeeModel).creationCode);        
        
        // Tape Model 
        bytes memory tapeModelCode = abi.encodePacked(type(TapeModel).creationCode);
        
        // Ownership Model 
        bytes memory ownershipModelCode = abi.encodePacked(type(OwnershipModel).creationCode);
        address ownershipModelAddress = Create2.computeAddress(SALT, keccak256(ownershipModelCode),DEPLOY_FACTORY);
        
        // Bonding Curve Model 
        bytes memory bcModelCode = abi.encodePacked(type(BondingCurveModel).creationCode);
        
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
        uint128[] memory ranges =  new uint128[](6); //[1,5,1000];
        ranges[0] = 1;
        ranges[1] = 1340;
        ranges[2] = 2942;
        ranges[3] = 5091;
        ranges[4] = 9161;
        ranges[5] = 10000;
        uint128[] memory coefficients = new uint128[](6);//[uint128(1000000000000000),uint128(1000000000000000),uint128(2000000000000000)];
        coefficients[0] = 1000000000000000;
        coefficients[1] = 23863899643421;
        coefficients[2] = 18753391400637;
        coefficients[3] = 10512971063653;
        coefficients[4] = 3046442261674;
        coefficients[5] = 817720774556;
        tape.updateBondingCurveParams(
            // newCurrencyToken, newFeeModel, newTapeModel, newTapeOwnershipModelAddress, newTapeBondingCurveModelAddress, newMaxSupply, stepRangesMax, stepCoefficients
            address(0), //currencyAddress,
            Create2.computeAddress(SALT, keccak256(feeModelCode),DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(tapeModelCode),DEPLOY_FACTORY),
            ownershipModelAddress,
            Create2.computeAddress(SALT, keccak256(bcModelCode),DEPLOY_FACTORY),
            10000, // max supply
            ranges,
            coefficients
        );

        if (!tape.dappAddresses(dappAddress)) {
            console.logString("Adding dapp address");
            tape.addDapp(dappAddress);
        }

        console.logString("Setting uri");
        tape.setURI("https://vanguard.rives.io/tapes/{id}");

        if (OwnershipModel(ownershipModelAddress).owner() != operatorAddress && OwnershipModel(ownershipModelAddress).owner() == tx.origin) {
            console.logString("Transfering ownership of ownership model from - to");
            console.logAddress(OwnershipModel(ownershipModelAddress).owner());
            console.logAddress(operatorAddress);
            OwnershipModel(ownershipModelAddress).transferOwnership(operatorAddress);
        }

        if (tape.owner() != operatorAddress && tape.owner() == tx.origin) {
            console.logString("Transfering ownership of tape from - to");
            console.logAddress(tape.owner());
            console.logAddress(operatorAddress);
            tape.transferOwnership(operatorAddress);
        }
        
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

