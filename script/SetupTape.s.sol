// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import {Script, console} from "forge-std/src/Script.sol";

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {TapeFeeModel} from "@models/TapeFeeModel.sol";
import {TapeModel} from "@models/TapeModel.sol";
import {TapeOwnershipModelWithProxy as OwnershipModel} from "@models/TapeOwnershipModelWithProxy.sol";
import {BondingCurveModel} from "@models/BondingCurveModel.sol";
import {TapeBondUtils} from "../src/TapeBondUtils.sol";
import {Tape} from "../src/Tape.sol";

contract SetupTape is Script {
    address constant DEPLOY_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    bytes32 constant SALT = bytes32(0);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address dappAddress = vm.envAddress("DAPP_ADDRESS");
        address operatorAddress = vm.envAddress("OPERATOR_ADDRESS");
        address worldAddress = vm.envAddress("WORLD_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        console.logString("Setup Tape Contracts");

        // Currency
        address currencyAddress = address(0);

        // Tape Fee Model
        bytes memory feeModelCode = abi.encodePacked(type(TapeFeeModel).creationCode);

        // Tape Model
        bytes memory tapeModelCode = abi.encodePacked(type(TapeModel).creationCode);

        // Ownership Model
        bytes memory ownershipModelCode =
            abi.encodePacked(type(OwnershipModel).creationCode, abi.encode(operatorAddress));
        address ownershipModelAddress = Create2.computeAddress(SALT, keccak256(ownershipModelCode), DEPLOY_FACTORY);

        // Bonding Curve Model
        bytes memory bcModelCode = abi.encodePacked(type(BondingCurveModel).creationCode);

        // Tape Bond Utils
        bytes memory tapeBondUtilsCode = abi.encodePacked(type(TapeBondUtils).creationCode);

        // Tape
        bytes memory tapeCode = abi.encodePacked(
            type(Tape).creationCode,
            abi.encode(
                operatorAddress,
                Create2.computeAddress(SALT, keccak256(tapeBondUtilsCode), DEPLOY_FACTORY),
                100 // max steps
            )
        );
        Tape tape = Tape(Create2.computeAddress(SALT, keccak256(tapeCode), DEPLOY_FACTORY));

        if (!tape.dappAddresses(dappAddress)) {
            console.logString("Adding dapp address");
            tape.setDapp(dappAddress, true);
        }

        console.logString("Setting uri");
        tape.setURI("https://vanguard.rives.io/tapes/{id}");

        if (
            OwnershipModel(ownershipModelAddress).owner() != operatorAddress
                && OwnershipModel(ownershipModelAddress).owner() == tx.origin
        ) {
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

        if (tape.owner() != operatorAddress && tape.owner() == tx.origin) {
            console.logString("Transfering ownership of tape from - to");
            console.logAddress(tape.owner());
            console.logAddress(operatorAddress);
            tape.transferOwnership(operatorAddress);
        }

        console.logString("Updating bonding curve params");

        // uint256[] memory ranges =  new uint256[](6); //[1,5,1000];
        // ranges[0] = 1;
        // ranges[1] = 1340;
        // ranges[2] = 2942;
        // ranges[3] = 5091;
        // ranges[4] = 9161;
        // ranges[5] = 10000;
        // uint256[] memory coefficients = new uint256[](6);//[uint256(1000000000000000),uint256(1000000000000000),uint256(2000000000000000)];
        // coefficients[0] = 1000000000000000;
        // coefficients[1] = 23863899643421;
        // coefficients[2] = 18753391400637;
        // coefficients[3] = 10512971063653;
        // coefficients[4] = 3046442261674;
        // coefficients[5] = 817720774556;

        uint256[] memory ranges = new uint256[](1); //[1,5,1000];
        ranges[0] = 10;
        uint256[] memory coefficients = new uint256[](1); //[uint256(1000000000000000),uint256(1000000000000000),uint256(2000000000000000)];
        coefficients[0] = 0;
        tape.updateBondingCurveParams(
            currencyAddress,
            Create2.computeAddress(SALT, keccak256(feeModelCode), DEPLOY_FACTORY),
            Create2.computeAddress(SALT, keccak256(tapeModelCode), DEPLOY_FACTORY),
            ownershipModelAddress,
            Create2.computeAddress(SALT, keccak256(bcModelCode), DEPLOY_FACTORY),
            10000 // max supply
        );

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
