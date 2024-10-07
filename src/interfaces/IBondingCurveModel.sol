// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IBondingCurveModel {
    error BC__InvalidBondParams(string reason);

    struct BondingCurveStep {
        uint256 rangeMax;
        uint256 coefficient;
    }

    function validateBondingCurve(
        bytes32 id,
        uint256[] memory stepRangesMax,
        uint256[] memory stepCoefficients,
        uint256 newMaxSupply
    ) external pure returns (BondingCurveStep[] memory);

    function validateBondParams(uint256 maxSteps, uint256[] memory stepRangesMax, uint256[] memory stepCoefficients)
        external
        pure;
}
