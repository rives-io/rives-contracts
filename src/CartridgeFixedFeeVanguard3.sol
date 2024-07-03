// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICartridgeFeeModel.sol";

contract CartridgeFixedFeeVanguard3 is ICartridgeFeeModel {

    function getMintFees(
        uint256,
        uint256,
        uint256
    ) override pure external returns (uint256,uint256) {
        return (0,0);
    }

    function getBurnFees(
        uint256,
        uint256,
        uint256
    ) override pure external returns (uint256,uint256) {
        return (0,0);
    }

    function getConsumeFees(
        uint256,
        uint256
    ) override pure external returns (uint256,uint256) {
        return (0, 0);
    }

}