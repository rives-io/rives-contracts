// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@interfaces/IBondingCurveModel.sol";

contract BondingCurveModel is IBondingCurveModel {
    function validateBondingCurve(
        bytes32, // id
        uint256[] memory stepRangesMax,
        uint256[] memory stepCoefficients,
        uint256 newMaxSupply
    ) external pure returns (BondingCurveStep[] memory) {
        if (stepRangesMax[stepRangesMax.length - 1] > newMaxSupply) {
            revert BC__InvalidBondParams("MAX_SUPPLY");
        }

        BondingCurveStep[] memory steps = new BondingCurveStep[](stepRangesMax.length);

        uint256 lastRangeMax;
        for (uint256 i = 0; i < stepRangesMax.length; ++i) {
            uint256 stepRangeMax = stepRangesMax[i];

            if (stepRangeMax == 0) {
                revert BC__InvalidBondParams("STEP_CANNOT_BE_ZERO");
            }
            if (stepRangeMax <= lastRangeMax) {
                revert BC__InvalidBondParams("STEP_CANNOT_BE_LESS_THAN_PREVIOUS");
            }

            steps[i] = BondingCurveStep({rangeMax: stepRangeMax, coefficient: stepCoefficients[i]});
            lastRangeMax = stepRangeMax;
        }

        return steps;
    }

    function validateBondParams(uint256 maxSteps, uint256[] memory stepRangesMax, uint256[] memory stepCoefficients)
        external
        pure
    {
        if (stepRangesMax.length == 0 || stepRangesMax.length > maxSteps) {
            revert BC__InvalidBondParams("INVALID_STEP_LENGTH");
        }
        if (stepCoefficients.length != stepRangesMax.length) {
            revert BC__InvalidBondParams("STEP_LENGTH_DO_NOT_MATCH");
        }
        // Last value or the rangeTo must be the same as the maxSupply
        // validateBondingCurve(stepRangesMax, stepCoefficients,newMaxSupply);
    }
}
