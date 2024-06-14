// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITapeFeeModel.sol";

contract TapeFixedFeeVanguard3 is ITapeFeeModel {

    // uint128 constant tapeCreatorFee = 1000; // for 6 decimals
    // uint128 constant protocolFee = 500; // for 6 decimals
    uint128 constant tapeCreatorFee = 100000000000000; // for 18 decimals
    uint128 constant protocolFee = 50000000000000; // for 18 decimals

    function getMintFees(
        uint256 amount,
        uint256
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        return (amount*protocolFee, 0, amount*tapeCreatorFee, 0);
    }

    function getBurnFees(
        uint256 amount,
        uint256
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        return (amount*protocolFee, 0, amount*tapeCreatorFee, 0);
    }

    function getConsumeFees(
        uint256 amount
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        return (0, 0, amount, 0);
    }

    function getTapesRoyaltiesFeesDistribution(
        uint256 , 
        uint256 
    ) override pure external returns (uint256[] memory) {
        return new uint256[](0);
    }

    function getRoyaltiesFees(
        uint256 amount
    ) override pure external returns (uint256,uint256) {
        return (0,amount);
    }

}