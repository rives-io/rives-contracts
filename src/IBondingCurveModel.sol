// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IBondingCurveModel {
    error BC__InvalidBondParams(string reason);

    struct BondingCurveStep {
        uint128 rangeMax;
        uint128 coefficient;
    }

    function validateBondingCurve(
        bytes32 id,
        uint128[] memory stepRangesMax, 
        uint128[] memory stepCoefficients, uint128 newMaxSupply) external pure returns(BondingCurveStep[] memory) ;

    function validateBondParams(uint256 maxSteps, uint128[] memory stepRangesMax, uint128[] memory stepCoefficients) pure external ;

}
