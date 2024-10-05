// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "@interfaces/IOwnershipModel.sol";
import "@interfaces/IBondingCurveModel.sol";

contract BondUtils {
    error Bond__InvalidCurrencyToken(string reason);
    error Bond__InvalidOwnershipModel(string reason);
    error Bond__InvalidCurrentSupply();
    error Bond__InvalidAmount();
    error Bond__ExceedSupply();

    event Buy(bytes32 indexed id, address indexed user, uint256 amountMinted, uint256 pricePayed);
    event Sell(bytes32 indexed id, address indexed user, uint256 amountBurned, uint256 refundReceived);
    event Consume(bytes32 indexed id, address indexed user, uint256 amountConsumed, uint256 currencyDonated);
    event Reward(
        bytes32 indexed id, address indexed user, address indexed token, RewardType rewardType, uint256 amount
    );
    event Bond(
        bytes32 indexed id, address indexed token, uint256 currentPrice, uint256 currentSupply, uint256 currentBalance
    );

    enum RewardType {
        ProtocolFee,
        RoyaltyFee,
        RoyaltyLeftover,
        ProtocolLeftover,
        CartridgeOwnerFee,
        TapeCreatorFee
    }

    struct UnclaimedFees {
        uint256 mint;
        uint256 burn;
        uint256 consume;
        uint256 royalties;
        uint256 undistributedRoyalties;
    }

    struct BondCount {
        uint256 minted;
        uint256 burned;
        uint256 consumed;
    }

    struct BondData {
        address currencyToken; // immutable
        IBondingCurveModel.BondingCurveStep[] steps; // immutable
        uint256 currencyBalance;
        uint256 currentSupply;
        uint256 currentPrice;
        uint256 consumePrice;
        UnclaimedFees unclaimed;
        BondCount count;
    }

    // Constants
    uint256 private constant MIN_BOOL_LENGTH = 31; // uint8 = 32 bytes
    uint256 private constant MIN_UINT8_LENGTH = 31; // uint8 = 32 bytes
    uint256 private constant MIN_STRING_LENGTH = 95; // empty string = 64 bytes, 1 character = 96 bytes

    // Aux/validation methods
    function verifyCurrencyToken(address newCurrencyToken) public view {
        // Accept base layer token as address 0
        if (newCurrencyToken == address(0)) return;

        if (!_checkMethodExists(newCurrencyToken, abi.encodeWithSignature("decimals()"), MIN_UINT8_LENGTH)) {
            revert Bond__InvalidCurrencyToken("decimals");
        }
        if (!_checkMethodExists(newCurrencyToken, abi.encodeWithSignature("name()"), MIN_STRING_LENGTH)) {
            revert Bond__InvalidCurrencyToken("name");
        }
        if (!_checkMethodExists(newCurrencyToken, abi.encodeWithSignature("symbol()"), MIN_STRING_LENGTH)) {
            revert Bond__InvalidCurrencyToken("symbol");
        }
    }

    function verifyOwnershipModel(address newModel) public view {
        if (newModel == address(0)) {
            revert Bond__InvalidOwnershipModel("address");
        }
        IOwnershipModel model = IOwnershipModel(newModel);
        if (
            !_checkMethodExists(
                newModel,
                abi.encodeWithSignature("checkOwner(address,bytes32)", address(0), bytes32(0)),
                MIN_BOOL_LENGTH
            )
        ) revert Bond__InvalidOwnershipModel("checkOwner");
        model.checkOwner(address(0), bytes32(0));
    }

    function _checkMethodExists(address implementation, bytes memory methodBytes, uint256 minLength)
        internal
        view
        returns (bool)
    {
        (bool success, bytes memory data) = implementation.staticcall(methodBytes);
        return success && data.length > minLength;
    }

    function getCurrentStep(uint256 currentSupply, BondData memory bond) public pure returns (uint256) {
        for (uint256 i = 0; i < bond.steps.length; ++i) {
            if (currentSupply <= bond.steps[i].rangeMax) {
                return i;
            }
        }
        revert Bond__InvalidCurrentSupply(); // can never happen
    }

    function getCurrencyAmoutToMintTokens(uint256 tokensToMint, BondData memory bond)
        public
        pure
        returns (uint256 currencyAmount, uint256 finalPrice)
    {
        if (tokensToMint == 0) revert Bond__InvalidAmount();

        IBondingCurveModel.BondingCurveStep[] memory steps = bond.steps;

        uint256 currentSupply = bond.currentSupply + bond.count.consumed;

        if (
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff - tokensToMint < currentSupply
                || currentSupply + tokensToMint > bond.steps[bond.steps.length - 1].rangeMax
        ) revert Bond__ExceedSupply();

        uint256 tokensLeft = tokensToMint;
        uint256 currencyAmountToBond;
        uint256 supplyLeft;
        uint256 priceAfter = bond.currentPrice;
        for (uint256 i = getCurrentStep(currentSupply, bond); i < steps.length; ++i) {
            IBondingCurveModel.BondingCurveStep memory step = steps[i];
            supplyLeft = step.rangeMax - currentSupply;

            if (supplyLeft < tokensLeft) {
                if (supplyLeft == 0) continue;

                // ensure reserve is calculated with ceiling
                // cp*n + c*(n+1))*n/2
                uint256 initialPrice = priceAfter + step.coefficient;
                priceAfter = priceAfter + step.coefficient * supplyLeft;
                currencyAmountToBond += Math.ceilDiv(supplyLeft * (initialPrice + priceAfter), 2);
                currentSupply += supplyLeft;
                tokensLeft -= supplyLeft;
            } else {
                // ensure reserve is calculated with ceiling
                uint256 initialPrice = priceAfter + step.coefficient;
                priceAfter = priceAfter + step.coefficient * tokensLeft;
                currencyAmountToBond += Math.ceilDiv(tokensLeft * (initialPrice + priceAfter), 2);
                tokensLeft = 0;
                break;
            }
        }

        if (tokensLeft > 0) revert Bond__InvalidAmount();

        finalPrice = priceAfter;
        currencyAmount = currencyAmountToBond;
    }

    function getCurrencyAmoutForBurningTokens(uint256 tokensToBurn, BondData memory bond)
        public
        pure
        returns (uint256 currencyAmount, uint256 finalPrice)
    {
        if (tokensToBurn == 0) revert Bond__InvalidAmount();

        IBondingCurveModel.BondingCurveStep[] memory steps = bond.steps;

        uint256 currentSupply = bond.currentSupply;

        if (tokensToBurn > currentSupply) revert Bond__ExceedSupply();

        // uint256 multiFactor = 10**t.decimals();
        uint256 currencyAmountFromBond;
        uint256 tokensLeft = tokensToBurn;
        uint256 i = getCurrentStep(currentSupply, bond);
        uint256 priceAfter = bond.currentPrice;
        while (tokensLeft > 0) {
            IBondingCurveModel.BondingCurveStep memory step = steps[i];
            uint256 supplyLeft = i == 0 ? currentSupply : currentSupply - steps[i - 1].rangeMax;

            uint256 tokensToProcess = tokensLeft < supplyLeft ? tokensLeft : supplyLeft;
            // reserveFromBond += ((tokensToProcess * steps[i].price) / multiFactor);

            if (tokensToProcess > 0) {
                uint256 initialPrice = priceAfter;
                priceAfter = priceAfter - step.coefficient * (tokensToProcess - 1);
                currencyAmountFromBond += Math.ceilDiv((tokensToProcess) * (initialPrice + priceAfter), 2);

                tokensLeft -= tokensToProcess;
                currentSupply -= tokensToProcess;
            }

            if (i == 0 && tokensToProcess == supplyLeft) priceAfter = 0;
            else priceAfter -= step.coefficient;

            if (i > 0) --i;
        }

        if (tokensLeft > 0) revert Bond__InvalidAmount();

        finalPrice = priceAfter;
        currencyAmount = currencyAmountFromBond;
    }

    function getCurrencyAmoutForConsumingTokens(uint256 tokensToConsume, BondData memory bond)
        public
        pure
        returns (uint256 currencyAmount, uint256 finalPrice)
    {
        if (tokensToConsume == 0) revert Bond__InvalidAmount();

        IBondingCurveModel.BondingCurveStep[] memory steps = bond.steps;

        uint256 currentConsumed = bond.count.consumed;

        if (
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff - tokensToConsume < currentConsumed
                || tokensToConsume + currentConsumed > bond.currentSupply
        ) revert Bond__ExceedSupply();

        uint256 tokensLeft = tokensToConsume;
        uint256 currencyAmountToBond;
        uint256 supplyLeft;
        uint256 priceAfter = bond.consumePrice;
        for (uint256 i = getCurrentStep(currentConsumed, bond); i < steps.length; ++i) {
            IBondingCurveModel.BondingCurveStep memory step = steps[i];
            supplyLeft = step.rangeMax - currentConsumed;

            if (supplyLeft < tokensLeft) {
                if (supplyLeft == 0) continue;

                // ensure reserve is calculated with ceiling
                // cp*n + c*(n+1))*n/2
                uint256 initialPrice = priceAfter + step.coefficient;
                priceAfter = priceAfter + step.coefficient * supplyLeft;
                currencyAmountToBond += Math.ceilDiv(supplyLeft * (initialPrice + priceAfter), 2);
                currentConsumed += supplyLeft;
                tokensLeft -= supplyLeft;
            } else {
                // ensure reserve is calculated with ceiling
                uint256 initialPrice = priceAfter + step.coefficient;
                priceAfter = priceAfter + step.coefficient * tokensLeft;
                currencyAmountToBond += Math.ceilDiv(tokensLeft * (initialPrice + priceAfter), 2);
                tokensLeft = 0;
                break;
            }
        }

        if (tokensLeft > 0) revert Bond__InvalidAmount();

        finalPrice = priceAfter;
        currencyAmount = currencyAmountToBond;
    }

    // XXX TODO change to bitwise operators
    function toHex(bytes memory buffer) public pure returns (string memory) {
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(converted);
    }
}
