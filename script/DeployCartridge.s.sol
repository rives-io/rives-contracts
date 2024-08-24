// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import { Script,console } from "forge-std/src/Script.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";


import { CartridgeMixedFeeVanguard4 as CartridgeFeeModel } from "../src/CartridgeMixedFeeVanguard4.sol";
import { CartridgeModelVanguard4 as CartridgeModel} from "../src/CartridgeModelVanguard4.sol";
import { CartridgeOwnershipModelVanguard4 as OwnershipModel } from "../src/CartridgeOwnershipModelVanguard4.sol";
import { BondingCurveModelVanguard3 as BondingCurveModel } from "../src/BondingCurveModelVanguard3.sol";
import { CartridgeBondUtils } from "../src/CartridgeBondUtils.sol";
import { Cartridge } from "../src/Cartridge.sol";


contract DeployCartridge is Script {
    address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 constant SALT = bytes32(0);
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address operatorAddress = vm.envAddress("OPERATOR_ADDRESS");
        // address dappAddress = vm.envAddress("DAPP_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        console.logString("Deploying Cartridge Contracts");

        // Currency 
        // address currencyAddress = address(0);

        // Cartridge Fee Model 
        bytes memory feeModelCode = abi.encodePacked(type(CartridgeFeeModel).creationCode);
        address feeModelAddress = Create2.computeAddress(SALT, keccak256(feeModelCode),DEPLOY_FACTORY);
        console.logString("Expected feeModelAddress");
        console.logAddress(feeModelAddress);
        if (checkSize(feeModelAddress) == 0) {
            CartridgeFeeModel feeModel = new CartridgeFeeModel{salt: SALT}();
            console.logString("Deployed feeModelAddress");
            console.logAddress(address(feeModel));
        } else {
            console.logString("Already deployed feeModelAddress");
        }
        
        // Cartridge Model 
        bytes memory cartridgeModelCode = abi.encodePacked(type(CartridgeModel).creationCode);
        address cartridgeModelAddress = Create2.computeAddress(SALT, keccak256(cartridgeModelCode),DEPLOY_FACTORY);
        console.logString("Expected cartridgeModelAddress");
        console.logAddress(cartridgeModelAddress);
        if (checkSize(cartridgeModelAddress) == 0) {
            CartridgeModel cartridgeModel = new CartridgeModel{salt: SALT}();
            console.logString("Deployed cartridgeModelAddress");
            console.logAddress(address(cartridgeModel));
        } else {
            console.logString("Already deployed cartridgeModelAddress");
        }
        
        // Ownership Model 
        bytes memory ownershipModelCode = abi.encodePacked(type(OwnershipModel).creationCode);
        address ownershipModelAddress = Create2.computeAddress(SALT, keccak256(ownershipModelCode),DEPLOY_FACTORY);
        console.logString("Expected ownershipModelAddress");
        console.logAddress(ownershipModelAddress);
        if (checkSize(ownershipModelAddress) == 0) {
            OwnershipModel ownershipModel = new OwnershipModel{salt: SALT}();
            console.logString("Deployed ownershipModelAddress");
            console.logAddress(address(ownershipModel));
            // console.logString("Transfering ownership of ownership model from - to");
            // console.logAddress(ownershipModel.owner());
            // console.logAddress(operatorAddress);
            // ownershipModel.transferOwnership(operatorAddress);
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
        
        // Cartridge Bond Utils
        bytes memory cartridgeBondUtilsCode = abi.encodePacked(type(CartridgeBondUtils).creationCode);
        address cartridgeBondUtilsAddress = Create2.computeAddress(SALT, keccak256(cartridgeBondUtilsCode),DEPLOY_FACTORY);
        console.logString("Expected cartridgeBondUtilsAddress");
        console.logAddress(cartridgeBondUtilsAddress);
        if (checkSize(cartridgeBondUtilsAddress) == 0) {
            CartridgeBondUtils cartridgeBondUtils = new CartridgeBondUtils{salt: SALT}();
            console.logString("Deployed cartridgeBondUtilsAddress");
            console.logAddress(address(cartridgeBondUtils));
        } else {
            console.logString("Already deployed cartridgeBondUtilsAddress");
        }
        
        // Cartridge
        bytes memory cartridgeCode = abi.encodePacked(type(Cartridge).creationCode,
            abi.encode(
                cartridgeBondUtilsAddress,
                100 // max steps
            )
        );
        address cartridgeAddress = Create2.computeAddress(SALT, keccak256(cartridgeCode),DEPLOY_FACTORY);
        console.logString("Expected cartridgeAddress");
        console.logAddress(cartridgeAddress);
        if (checkSize(cartridgeAddress) == 0) {
            Cartridge cartridge = new Cartridge{salt: SALT}(
                cartridgeBondUtilsAddress,
                100 // max steps
            );
            console.logString("Deployed cartridgeAddress");
            console.logAddress(address(cartridge));
            // console.logString("Transfering ownership of cartridge contract fom - to");
            // console.logAddress(cartridge.owner());
            // console.logAddress(operatorAddress);
            // cartridge.transferOwnership(operatorAddress);
        } else {
            console.logString("Already deployed cartridgeAddress");
        }



        // uint128[] memory ranges =  new uint128[](3); //[1,5,1000];
        // ranges[0] = 1;
        // ranges[1] = 5;
        // ranges[2] = 1000;
        // uint128[] memory coefficients = new uint128[](3);//[uint128(1000000000000000),uint128(1000000000000000),uint128(2000000000000000)];
        // coefficients[0] = 1000000000000000;
        // coefficients[1] = 1000000000000000;
        // coefficients[2] = 2000000000000000;
        // cartridge.updateBondingCurveParams(
        //     // newCurrencyToken, newFeeModel, newCartridgeModel, newCartridgeOwnershipModelAddress, newCartridgeBondingCurveModelAddress, newMaxSupply, stepRangesMax, stepCoefficients
        //     address(0), //currencyAddress,
        //     feeModelAddress,
        //     cartridgeModelAddress,
        //     ownershipModelAddress,
        //     bcModelAddress,
        //     1000, // max supply
        //     ranges,
        //     coefficients
        // );

        // cartridge.addDapp(dappAddress);

        vm.stopBroadcast();
    }

    function checkSize(address addr) public view returns(uint extSize) {
        assembly {
            extSize := extcodesize(addr) // returns 0 if EOA, >0 if smart contract
        }
    }
    
}

// # cartridge asset
// MAX_STEPS=100
// MAX_SUPPLY=1000
// RANGES="[1,5,1000]"
// # COEFS="[10000,1000,2000]"
// COEFS="[1000000000000000,1000000000000000,2000000000000000]"

// ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $TAPE_FEE_MODEL $TAPE_MODEL $OWNERSHIP_MODEL $BC_MODEL $TAPE_BOND_UTILS $MAX_SUPPLY $RANGES $COEFS"

