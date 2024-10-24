// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICartridgeFeeModel {
    function getMintFees(uint256 confParam, uint256 amount, uint256 price) external pure returns (uint256, uint256);
    function getBurnFees(uint256 confParam, uint256 amount, uint256 price) external pure returns (uint256, uint256);
    function getConsumeFees(uint256 confParam, uint256 amount) external pure returns (uint256, uint256);
}
