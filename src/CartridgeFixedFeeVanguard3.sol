// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICartridgeFeeModel.sol";

contract CartridgeFixedFeeVanguard3 is ICartridgeFeeModel {

    // uint128 constant cartridgeOwnerFee = 1000;
    // uint128 constant protocolFee = 500;

    // function getMintFees(
    //     uint256 amount,
    //     uint256
    // ) override pure external returns (uint256,uint256) {
    //     return (amount*protocolFee, amount*cartridgeOwnerFee);
    // }

    // function getBurnFees(
    //     uint256 amount,
    //     uint256
    // ) override pure external returns (uint256,uint256) {
    //     return (amount*protocolFee, amount*cartridgeOwnerFee);
    // }

    // function getConsumeFees(
    //     uint256 amount
    // ) override pure external returns (uint256,uint256) {
    //     return (0, amount);
    // }

    function getMintFees(
        uint256 ,
        uint256
    ) override pure external returns (uint256,uint256) {
        return (0,0);
    }

    function getBurnFees(
        uint256 ,
        uint256
    ) override pure external returns (uint256,uint256) {
        return (0,0);
    }

    function getConsumeFees(
        uint256
    ) override pure external returns (uint256,uint256) {
        return (0, 0);
    }

}