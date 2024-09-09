// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import { Script,console } from "forge-std/src/Script.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";


import { TapeFeeModel } from "../src/TapeFeeModel.sol";
import { TapeModel } from "../src/TapeModel.sol";
import { TapeOwnershipModelWithProxy as OwnershipModel } from "../src/TapeOwnershipModelWithProxy.sol";
import { BondingCurveModel } from "../src/BondingCurveModel.sol";
import { TapeBondUtils } from "../src/TapeBondUtils.sol";
import { Tape } from "../src/Tape.sol";


contract DeployTape is Script {
    address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 constant SALT = bytes32(0);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address operatorAddress = vm.envAddress("OPERATOR_ADDRESS");
        // address dappAddress = vm.envAddress("DAPP_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        console.logString("Deploying Tape Contracts");

        // Tape Fee Model 
        bytes memory feeModelCode = abi.encodePacked(type(TapeFeeModel).creationCode);
        address feeModelAddress = Create2.computeAddress(SALT, keccak256(feeModelCode),DEPLOY_FACTORY);
        console.logString("Expected feeModelAddress");
        console.logAddress(feeModelAddress);
        if (checkSize(feeModelAddress) == 0) {
            TapeFeeModel feeModel = new TapeFeeModel{salt: SALT}();
            console.logString("Deployed feeModelAddress");
            console.logAddress(address(feeModel));
        } else {
            console.logString("Already deployed feeModelAddress");
        }
        
        // Tape Model 
        bytes memory tapeModelCode = abi.encodePacked(type(TapeModel).creationCode);
        address tapeModelAddress = Create2.computeAddress(SALT, keccak256(tapeModelCode),DEPLOY_FACTORY);
        console.logString("Expected tapeModelAddress");
        console.logAddress(tapeModelAddress);
        if (checkSize(tapeModelAddress) == 0) {
            TapeModel tapeModel = new TapeModel{salt: SALT}();
            console.logString("Deployed tapeModelAddress");
            console.logAddress(address(tapeModel));
        } else {
            console.logString("Already deployed tapeModelAddress");
        }
        
        // Ownership Model 
        bytes memory ownershipModelCode = abi.encodePacked(type(OwnershipModel).creationCode,abi.encode(operatorAddress));
        address ownershipModelAddress = Create2.computeAddress(SALT, keccak256(ownershipModelCode),DEPLOY_FACTORY);
        console.logString("Expected ownershipModelAddress");
        console.logAddress(ownershipModelAddress);
        if (checkSize(ownershipModelAddress) == 0) {
            OwnershipModel ownershipModel = new OwnershipModel{salt: SALT}(operatorAddress);
            console.logString("Deployed ownershipModelAddress");
            console.logAddress(address(ownershipModel));
        } else {
            console.logString("Already deployed ownershipModelAddress");
        }

        
        // Bonding Curve Model 
        bytes memory bcModelCode = abi.encodePacked(type(BondingCurveModel).creationCode);
        address bcModelAddress = Create2.computeAddress(SALT, keccak256(bcModelCode),DEPLOY_FACTORY);
        console.logString("Expected bcModelAddress");
        console.logAddress(bcModelAddress);
        if (checkSize(bcModelAddress) == 0) {
            BondingCurveModel bcModel = new BondingCurveModel{salt: SALT}();
            console.logString("Deployed bcModelAddress");
            console.logAddress(address(bcModel));
        } else {
            console.logString("Already deployed bcModelAddress");
        }
        
        // Tape Bond Utils
        bytes memory tapeBondUtilsCode = abi.encodePacked(type(TapeBondUtils).creationCode);
        address tapeBondUtilsAddress = Create2.computeAddress(SALT, keccak256(tapeBondUtilsCode),DEPLOY_FACTORY);
        console.logString("Expected tapeBondUtilsAddress");
        console.logAddress(tapeBondUtilsAddress);
        if (checkSize(tapeBondUtilsAddress) == 0) {
            TapeBondUtils tapeBondUtils = new TapeBondUtils{salt: SALT}();
            console.logString("Deployed tapeBondUtilsAddress");
            console.logAddress(address(tapeBondUtils));
        } else {
            console.logString("Already deployed tapeBondUtilsAddress");
        }
        
        // Tape
        bytes memory tapeCode = abi.encodePacked(type(Tape).creationCode,
            abi.encode(
                operatorAddress,
                tapeBondUtilsAddress,
                100 // max steps
            )
        );
        address tapeAddress = Create2.computeAddress(SALT, keccak256(tapeCode),DEPLOY_FACTORY);
        console.logString("Expected tapeAddress");
        console.logAddress(tapeAddress);
        if (checkSize(tapeAddress) == 0) {
            Tape tape = new Tape{salt: SALT}(
                operatorAddress,
                tapeBondUtilsAddress,
                100 // max steps
            );
            console.logString("Deployed tapeAddress");
            console.logAddress(address(tape));
        } else {
            console.logString("Already deployed tapeAddress");
        }

        vm.stopBroadcast();
    }

    function checkSize(address addr) public view returns(uint extSize) {
        assembly {
            extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
        }
    }
    
}

// # tape asset
// MAX_STEPS=100
// MAX_SUPPLY=1000
// RANGES="[1,5,1000]"
// # COEFS="[10000,1000,2000]"
// COEFS="[1000000000000000,1000000000000000,2000000000000000]"

// ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $TAPE_FEE_MODEL $TAPE_MODEL $OWNERSHIP_MODEL $BC_MODEL $TAPE_BOND_UTILS $MAX_SUPPLY $RANGES $COEFS"

