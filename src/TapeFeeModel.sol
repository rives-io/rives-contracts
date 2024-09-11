// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITapeFeeModel.sol";

contract TapeFeeModel is ITapeFeeModel {

    uint128 constant feeProportionPerK = 100;
    uint128 constant protocolFeeProportionPerK = 100;
    uint128 constant cartridgeFeeProportionPerK = 300;

    // function getMintFees(
    //     uint256 feeProportionPerK,
    //     uint256, // amount,
    //     uint256 totalPrice
    // ) override pure external returns (uint256,uint256) {
    //     uint256 totalFees = totalPrice * feeProportionPerK / 1000;
    //     uint256 protocolFee = totalFees * protocolFeeProportionPerK / 1000;
    //     return (protocolFee, totalFees - protocolFee);
    // }

    function getMintFees(
        uint256,
        uint256 totalPrice
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        uint256 totalFees = totalPrice * feeProportionPerK / 1000;
        uint256 protocolFee = totalFees * protocolFeeProportionPerK / 1000;
        uint256 cartridgeOwnerFee = totalFees * cartridgeFeeProportionPerK / 1000;
        return (protocolFee, cartridgeOwnerFee, totalFees - protocolFee - cartridgeOwnerFee, 0);
    }

    function getBurnFees(
        uint256,
        uint256 totalPrice
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        uint256 totalFees = totalPrice * feeProportionPerK / 1000;
        uint256 protocolFee = totalFees * protocolFeeProportionPerK / 1000;
        uint256 cartridgeOwnerFee = totalFees * cartridgeFeeProportionPerK / 1000;
        return (protocolFee, cartridgeOwnerFee, totalFees - protocolFee - cartridgeOwnerFee, 0);
    }

    function getConsumeFees(
        uint256 amount
    ) override pure external returns (uint256,uint256,uint256,uint256) {
        uint256 cartridgeOwnerFee = amount * cartridgeFeeProportionPerK / 1000;
        return (0, cartridgeOwnerFee, amount - cartridgeOwnerFee, 0);
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