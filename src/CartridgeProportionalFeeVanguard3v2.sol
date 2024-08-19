// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICartridgeFeeModel.sol";

contract CartridgeProportionalFeeVanguard3v2 is ICartridgeFeeModel {

    uint256 constant protocolFeeProportionPerK = 100;

    function getMintFees(
        uint256 feeProportionPerK,
        uint256, // amount,
        uint256 totalPrice
    ) override pure external returns (uint256,uint256) {
        uint256 totalFees = totalPrice * feeProportionPerK / 1000;
        uint256 protocolFee = totalFees * protocolFeeProportionPerK / 1000;
        return (protocolFee, totalFees - protocolFee);
    }

    function getBurnFees(
        uint256 feeProportionPerK,
        uint256, // amount,
        uint256 totalPrice
    ) override pure external returns (uint256,uint256) {
        uint256 totalFees = totalPrice * feeProportionPerK / 1000;
        uint256 protocolFee = totalFees * protocolFeeProportionPerK / 1000;
        return (protocolFee, totalFees - protocolFee);
    }

    function getConsumeFees(
        uint256,
        uint256 amount
    ) override pure external returns (uint256,uint256) {
        return (0, amount);
    }

}