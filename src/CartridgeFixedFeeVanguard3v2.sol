// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICartridgeFeeModel.sol";

contract CartridgeFixedFeeVanguard3v2 is ICartridgeFeeModel {

    // uint128 constant cartridgeOwnerFee = 1000; // for 6 decimals
    // uint128 constant protocolFee = 500; // for 6 decimals
    uint128 constant cartridgeOwnerFee = 100000000000000; // for 18 decimals
    uint128 constant protocolFee = 50000000000000; // for 18 decimals

    function getMintFees(
        uint256,
        uint256 amount,
        uint256
    ) override pure external returns (uint256,uint256) {
        return (amount*protocolFee, amount*cartridgeOwnerFee);
    }

    function getBurnFees(
        uint256,
        uint256 amount,
        uint256
    ) override pure external returns (uint256,uint256) {
        return (amount*protocolFee, amount*cartridgeOwnerFee);
    }

    function getConsumeFees(
        uint256,
        uint256 amount
    ) override pure external returns (uint256,uint256) {
        return (0, amount);
    }

}