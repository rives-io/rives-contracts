// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "@interfaces/ICartridgeFeeModel.sol";
import "@interfaces/ICartridgeModel.sol";
import "@interfaces/IOwnershipModel.sol";
import "@interfaces/IBondingCurveModel.sol";
import "./BondUtils.sol";

contract CartridgeBondUtils is BondUtils {
    error Cartridge__InvalidFeeModel(string reason);
    error Cartridge__InvalidCartridgeModel(string reason);

    struct CartridgeBond {
        BondUtils.BondData bond;
        address feeModel; // immutable
        uint256 feeConfig; // immutable
        address cartridgeModel; // immutable
        // address[2] addresses; // cartridgeOwner CartridgeCreator; // reduce number of var
        address cartridgeOwner;
        uint256 lastUpdate;
        bytes eventData;
    }

    // Constants
    uint256 private constant MIN_2BYTES32_LENGTH = 63; // uint256 = 32 bytes * 2
    uint256 private constant MIN_4BYTES32_LENGTH = 127; // uint256 = 32 bytes * 4
    uint256 private constant MIN_7BYTES32_LENGTH = 223; // uint256 = 32 bytes * 7
    uint256 private constant MIN_ARRAY_LENGTH = 63; // empty array = 64 bytes = 64 bytes

    function verifyFeeModel(address newFeeModel) public view {
        if (newFeeModel == address(0)) {
            revert Cartridge__InvalidFeeModel("address");
        }
        ICartridgeFeeModel model = ICartridgeFeeModel(newFeeModel);
        if (
            !_checkMethodExists(
                newFeeModel,
                abi.encodeWithSignature("getMintFees(uint256,uint256,uint256)", uint256(0), 0, 0),
                MIN_2BYTES32_LENGTH
            )
        ) revert Cartridge__InvalidFeeModel("getMintFees");
        model.getMintFees(uint256(0), 0, 0);
        if (
            !_checkMethodExists(
                newFeeModel,
                abi.encodeWithSignature("getBurnFees(uint256,uint256,uint256)", uint256(0), 0, 0),
                MIN_2BYTES32_LENGTH
            )
        ) revert Cartridge__InvalidFeeModel("getBurnFees");
        model.getBurnFees(uint256(0), 0, 0);
        if (
            !_checkMethodExists(
                newFeeModel,
                abi.encodeWithSignature("getConsumeFees(uint256,uint256)", uint256(0), 0),
                MIN_2BYTES32_LENGTH
            )
        ) revert Cartridge__InvalidFeeModel("getConsumeFees");
        model.getConsumeFees(uint256(0), 0);
    }

    function verifyCartridgeModel(address newCartridgeModel) public view {
        if (newCartridgeModel == address(0)) {
            revert Cartridge__InvalidCartridgeModel("address");
        }
        ICartridgeModel model = ICartridgeModel(newCartridgeModel);
        if (
            !_checkMethodExists(
                newCartridgeModel, abi.encodeWithSignature("decodeCartridgeUser(bytes)", ""), MIN_2BYTES32_LENGTH
            )
        ) revert Cartridge__InvalidCartridgeModel("decodeCartridgeUser");
        model.decodeCartridgeUser("");
        if (
            !_checkMethodExists(
                newCartridgeModel, abi.encodeWithSignature("decodeCartridgeMetadata(bytes)", ""), MIN_4BYTES32_LENGTH
            )
        ) revert Cartridge__InvalidCartridgeModel("decodeCartridgeMetadata");
        model.decodeCartridgeMetadata("");
    }
}
