// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "./ITapeFeeModel.sol";
import "./ITapeModel.sol";
import "./IOwnershipModel.sol";
import "./IBondingCurveModel.sol";
import "./BondUtils.sol";

contract TapeBondUtils is BondUtils {
    error Tape__InvalidFeeModel(string reason);
    error Tape__InvalidTapeModel(string reason);

    struct TapeBond {
        BondUtils.BondData bond;
        address feeModel; // immutable
        address tapeModel; // immutable
        // address[2] addresses; // cartridgeOwner TapeCreator; // reduce number of var
        address cartridgeOwner;
        address tapeCreator;
        // bytes32[] royaltiesTapes;
        bytes tapeOutputData;
    }

    // Constants
    uint256 private constant MIN_2BYTES32_LENGTH = 63; // uint256 = 32 bytes * 2
    uint256 private constant MIN_3BYTES32_LENGTH = 95; // uint256 = 32 bytes * 3
    uint256 private constant MIN_4BYTES32_LENGTH = 127; // uint256 = 32 bytes * 4
    uint256 private constant MIN_9BYTES32_LENGTH = 287; // uint256 = 32 bytes * 9
    uint256 private constant MIN_ARRAY_LENGTH = 63; // empty array = 64 bytes = 64 bytes

    function verifyFeeModel(address newFeeModel) public view {
        if (newFeeModel == address(0)) revert Tape__InvalidFeeModel("address");
        ITapeFeeModel model = ITapeFeeModel(newFeeModel);
        if (
            !_checkMethodExists(
                newFeeModel, abi.encodeWithSignature("getMintFees(uint256,uint256)", 0, 0), MIN_4BYTES32_LENGTH
            )
        ) revert Tape__InvalidFeeModel("getMintFees");
        model.getMintFees(0, 0);
        if (
            !_checkMethodExists(
                newFeeModel, abi.encodeWithSignature("getBurnFees(uint256,uint256)", 0, 0), MIN_4BYTES32_LENGTH
            )
        ) revert Tape__InvalidFeeModel("getBurnFees");
        model.getBurnFees(0, 0);
        if (
            !_checkMethodExists(newFeeModel, abi.encodeWithSignature("getConsumeFees(uint256)", 0), MIN_4BYTES32_LENGTH)
        ) revert Tape__InvalidFeeModel("getConsumeFees");
        model.getConsumeFees(0);
        if (
            !_checkMethodExists(
                newFeeModel,
                abi.encodeWithSignature("getTapesRoyaltiesFeesDistribution(uint256,uint256)", 0, 0),
                MIN_ARRAY_LENGTH
            )
        ) revert Tape__InvalidFeeModel("getTapesRoyaltiesFeesDistribution");
        model.getTapesRoyaltiesFeesDistribution(0, 0);
        if (
            !_checkMethodExists(
                newFeeModel, abi.encodeWithSignature("getRoyaltiesFees(uint256)", 0), MIN_2BYTES32_LENGTH
            )
        ) revert Tape__InvalidFeeModel("getRoayaltiesFees");
        model.getRoyaltiesFees(0);
    }

    function verifyTapeModel(address newTapeModel) public view {
        if (newTapeModel == address(0)) {
            revert Tape__InvalidTapeModel("address");
        }
        ITapeModel model = ITapeModel(newTapeModel);
        if (
            !_checkMethodExists(newTapeModel, abi.encodeWithSignature("getRoyaltiesTapes(bytes)", ""), MIN_ARRAY_LENGTH)
        ) revert Tape__InvalidTapeModel("getRoyaltiesTapes");
        model.getRoyaltiesTapes("");
        if (
            !_checkMethodExists(newTapeModel, abi.encodeWithSignature("decodeTapeUsers(bytes)", ""), MIN_3BYTES32_LENGTH)
        ) revert Tape__InvalidTapeModel("decodeTapeUsers");
        model.decodeTapeUsers("");
        if (
            !_checkMethodExists(
                newTapeModel, abi.encodeWithSignature("decodeTapeMetadata(bytes)", ""), MIN_9BYTES32_LENGTH
            )
        ) revert Tape__InvalidTapeModel("decodeTapeMetadata");
        model.decodeTapeMetadata("");
    }
}
