// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITapeFeeModel {
    function getMintFees(uint256 amount, uint256 price) pure external returns (uint256,uint256,uint256,uint256);
    function getBurnFees(uint256 amount, uint256 price) pure external returns (uint256,uint256,uint256,uint256);
    function getConsumeFees(uint256 amount) pure external returns (uint256,uint256,uint256,uint256);
    function getTapesRoyaltiesFeesDistribution(uint256 value, uint256 nTapes) pure external returns (uint256[] memory);
    function getRoyaltiesFees(uint256 amount) pure external returns (uint256,uint256);
}
