// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITapeFeeModel.sol";

contract TapeFixedFeeVanguard3v2 is ITapeFeeModel {

    // uint256 constant cartridgeOwnerFee = 1000; // for 6 decimals
    // uint256 constant tapeCreatorFee = 1000; // for 6 decimals
    // uint256 constant protocolFee = 500; // for 6 decimals
    uint256 constant cartridgeOwnerFee = 100000000000000; // for 18 decimals
    uint256 constant tapeCreatorFee = 100000000000000; // for 18 decimals
    uint256 constant protocolFee = 50000000000000; // for 18 decimals

    function getMintFees(
        uint256 amount,
        uint256
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        return (amount*protocolFee, amount*cartridgeOwnerFee, amount*tapeCreatorFee, 0);
    }

    function getBurnFees(
        uint256 amount,
        uint256
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        return (amount*protocolFee, amount*cartridgeOwnerFee, amount*tapeCreatorFee, 0);
    }

    function getConsumeFees(
        uint256 amount
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        uint256 coFee = amount * 25 / 100;
        return (0, coFee, amount - coFee, 0);
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