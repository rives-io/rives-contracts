// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@interfaces/ITapeFeeModel.sol";

contract TapeFixedFeeModel is ITapeFeeModel {
    uint256 constant cartridgeOwnerFee = 1000;
    uint256 constant tapeCreatorFee = 1000;
    uint256 constant protocolFee = 500;
    uint256 constant royaltiesFee = 500;

    function getMintFees(uint256 amount, uint256) external pure override returns (uint256, uint256, uint256, uint256) {
        return (amount * protocolFee, amount * cartridgeOwnerFee, amount * tapeCreatorFee, amount * royaltiesFee);
    }

    function getBurnFees(uint256 amount, uint256) external pure override returns (uint256, uint256, uint256, uint256) {
        return (amount * protocolFee, amount * cartridgeOwnerFee, amount * tapeCreatorFee, amount * royaltiesFee);
    }

    function getConsumeFees(uint256 amount) external pure override returns (uint256, uint256, uint256, uint256) {
        uint256 cartridgeOwnerAmount =
            (amount * cartridgeOwnerFee) / (cartridgeOwnerFee + tapeCreatorFee + royaltiesFee);
        uint256 royaltiesAmount = (amount * cartridgeOwnerFee) / (cartridgeOwnerFee + tapeCreatorFee + royaltiesFee);
        uint256 tapeCreatorAmount = amount - cartridgeOwnerAmount;
        return (0, cartridgeOwnerAmount, tapeCreatorAmount, royaltiesAmount);
    }

    function getTapesRoyaltiesFeesDistribution(uint256 value, uint256 nTapes)
        external
        pure
        override
        returns (uint256[] memory)
    {
        uint256[] memory tapeFees = new uint256[](nTapes);
        uint256 total;
        for (uint256 i = 0; i < nTapes; ++i) {
            tapeFees[i] = value / nTapes;
            total += tapeFees[i];
        }
        uint256 leftover = value - total;
        if (nTapes > 0 && leftover > 0) tapeFees[0] += leftover;
        return tapeFees;
    }

    function getRoyaltiesFees(uint256 amount) external pure override returns (uint256, uint256) {
        uint256 cartridgeOwnerAmount = (amount * cartridgeOwnerFee) / (cartridgeOwnerFee + tapeCreatorFee);
        uint256 tapeCreatorAmount = amount - cartridgeOwnerAmount;
        return (cartridgeOwnerAmount, tapeCreatorAmount);
    }
}
