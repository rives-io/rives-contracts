// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICartridgeFeeModel {
    function getMintFees(uint256 amount, uint256 price) pure external returns (uint256,uint256);
    function getBurnFees(uint256 amount, uint256 price) pure external returns (uint256,uint256);
    function getConsumeFees(uint256 amount) pure external returns (uint256,uint256);
}
