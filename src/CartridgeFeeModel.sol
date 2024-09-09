// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICartridgeFeeModel.sol";

contract CartridgeFeeModel is ICartridgeFeeModel {

    uint256 constant protocolFeeProportionPerK = 100; // 10%

    function getMintFees(
        uint256 feeConfig, // fee config
        uint256 amount,
        uint256 totalPrice
    ) override pure external returns (uint256,uint256) {
        uint256 protocolFee;
        // bc has a value
        if (totalPrice > 0) {
            // feeConfig as feeProportionPerK
            uint256 totalFees = totalPrice * feeConfig / 1000;
            protocolFee = totalFees * protocolFeeProportionPerK / 1000;
            return (protocolFee, totalFees - protocolFee);
        }
        // feeConfig as price
        uint256 totalFee = feeConfig * amount;
        protocolFee = totalFee * protocolFeeProportionPerK / 1000;
        return (protocolFee, feeConfig - protocolFee);
    }

    function getBurnFees(
        uint256 feeConfig, // fee config
        uint256 ,
        uint256 totalPrice
    ) override pure external returns (uint256,uint256) {
        uint256 protocolFee;
        // bc has a value
        if (totalPrice > 0) {
            // feeConfig as feeProportionPerK
            uint256 totalFees = totalPrice * feeConfig / 1000;
            protocolFee = totalFees * protocolFeeProportionPerK / 1000;
            return (protocolFee, totalFees - protocolFee);
        }
        // total price is 0, can't charge fees
        return (0,0);
    }

    function getConsumeFees(
        uint256, // fee config
        uint256 totalValue
    ) override pure external returns (uint256,uint256) {
        return (0, totalValue); // protocol, cartridge owner
    }

}