// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "./ITapeFeeModel.sol";
import "./ITapeModel.sol";

contract TapeBondUtils {
    error Tape__InvalidCurrencyToken(string reason);
    error Tape__InsufficientFunds();
    error Tape__ChangeError();
    error Tape__InvalidFeeModel(string reason);
    error Tape__InvalidTapeModel(string reason);
    error Tape__InvalidBondParams(string reason);
    error Tape__NotFound();
    error Tape__InvalidUser();
    error Tape__InvalidCurrentSupply();
    error Tape__InvalidAmount();
    error Tape__InvalidDapp();
    error Tape__InvalidTape(string reason);
    error Tape__ExceedSupply();
    // error Tape__InvalidReceiver();
    error Tape__SlippageLimitExceeded();
    
    event Buy(bytes32 indexed tapeId, address indexed user, uint256 amountMinted, uint256 pricePayed);
    event Sell(bytes32 indexed tapeId, address indexed user, uint256 amountBurned, uint256 refundReceived);
    event Consume(bytes32 indexed tapeId, address indexed user, uint256 amountConsumed, uint256 currencyDonated);
    event Reward(bytes32 indexed tapeId, address indexed user, address indexed token, uint256 amount, RewardType rewardType);

    enum RewardType {
        ProtocolFee,
        CartridgeOwnerFee,
        TapeCreatorFee,
        RoyaltyFee,
        RoyaltyLeftover,
        ProtocolLeftover
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
    
    struct TapeBond {
        address feeModel; // immutable
        address currencyToken; // immutable
        address tapeModel; // immutable
        // mapping (uint8 => BondingCurveStep) steps; // immutable
        // uint8 stepsSize;
        BondingCurveStep[] steps; // immutable
        uint256 currencyBalance;
        uint256 currentSupply;
        uint256 currentPrice;
        uint256 consumePrice;
        UnclaimedFees unclaimed;
        BondCount count;
        // address[2] addresses; // cartridgeOwner TapeCreator; // reduce number of var
        address cartridgeOwner;
        address tapeCreator;
        // bytes32[] royaltiesTapes;
        bytes tapeOutputData;
    }

    struct BondingCurveStep {
        uint128 rangeMax;
        uint128 coefficient;
    }

    // Constants
    uint256 private constant MIN_UINT8_LENGTH = 31; // uint8 = 32 bytes
    uint256 private constant MIN_STRING_LENGTH = 95; // empty string = 64 bytes, 1 character = 96 bytes
    uint256 private constant MIN_2BYTES32_LENGTH = 63; // uint256 = 32 bytes * 2
    uint256 private constant MIN_3BYTES32_LENGTH = 95; // uint256 = 32 bytes * 3
    uint256 private constant MIN_4BYTES32_LENGTH = 127; // uint256 = 32 bytes * 4
    uint256 private constant MIN_7BYTES32_LENGTH = 223; // uint256 = 32 bytes * 7
    uint256 private constant MIN_ARRAY_LENGTH = 63; // empty array = 64 bytes = 64 bytes
    uint256 private constant MIN_2ADDRESS_LENGTH = 63; // address = 32 bytes * 2


    // Aux/validation methods
    function verifyCurrencyToken(address newCurrencyToken) view public {
        // if (newCurrencyToken == address(0)) revert Tape__InvalidCurrencyToken('address');
        // Accept base layer token as address 0
        if (newCurrencyToken == address(0)) return;

        if(!_checkMethodExists(newCurrencyToken, abi.encodeWithSignature("decimals()"), MIN_UINT8_LENGTH)) 
            revert Tape__InvalidCurrencyToken('decimals');
        if(!_checkMethodExists(newCurrencyToken, abi.encodeWithSignature("name()"), MIN_STRING_LENGTH)) 
            revert Tape__InvalidCurrencyToken('name');
        if(!_checkMethodExists(newCurrencyToken, abi.encodeWithSignature("symbol()"), MIN_STRING_LENGTH)) 
            revert Tape__InvalidCurrencyToken('symbol');
    }

    function verifyFeeModel(address newFeeModel) view public {
        if (newFeeModel == address(0)) revert Tape__InvalidFeeModel('address');
        ITapeFeeModel model = ITapeFeeModel(newFeeModel);
        if(!_checkMethodExists(newFeeModel, abi.encodeWithSignature("getMintFees(uint256,uint256)",0,0), MIN_4BYTES32_LENGTH)) 
            revert Tape__InvalidFeeModel('getMintFees');
        model.getMintFees(0,0);
        if(!_checkMethodExists(newFeeModel, abi.encodeWithSignature("getBurnFees(uint256,uint256)",0,0), MIN_4BYTES32_LENGTH)) 
            revert Tape__InvalidFeeModel('getBurnFees');
        model.getBurnFees(0,0);
        if(!_checkMethodExists(newFeeModel, abi.encodeWithSignature("getConsumeFees(uint256)",0), MIN_4BYTES32_LENGTH)) 
            revert Tape__InvalidFeeModel('getConsumeFees');
        model.getConsumeFees(0);
        if(!_checkMethodExists(newFeeModel, abi.encodeWithSignature("getTapesRoyaltiesFeesDistribution(uint256,uint256)",0,0), MIN_ARRAY_LENGTH)) 
            revert Tape__InvalidFeeModel('getTapesRoyaltiesFeesDistribution');
        model.getTapesRoyaltiesFeesDistribution(0,0);
        if(!_checkMethodExists(newFeeModel, abi.encodeWithSignature("getRoyaltiesFees(uint256)",0), MIN_2BYTES32_LENGTH)) 
            revert Tape__InvalidFeeModel('getRoayaltiesFees');
        model.getRoyaltiesFees(0);
    }

    function verifyTapeModel(address newTapeModel) view public {
        if (newTapeModel == address(0)) revert Tape__InvalidTapeModel('address');
        ITapeModel model = ITapeModel(newTapeModel);
        if(!_checkMethodExists(newTapeModel, abi.encodeWithSignature("getRoyaltiesTapes(bytes)",""), MIN_ARRAY_LENGTH)) 
            revert Tape__InvalidTapeModel('getRoyaltiesTapes');
        model.getRoyaltiesTapes("");
        if(!_checkMethodExists(newTapeModel, abi.encodeWithSignature("decodeTapeUsers(bytes)",""), MIN_3BYTES32_LENGTH)) 
            revert Tape__InvalidTapeModel('decodeTapeUsers');
        model.decodeTapeUsers("");
        if(!_checkMethodExists(newTapeModel, abi.encodeWithSignature("decodeTapeMetadata(bytes)",""), MIN_7BYTES32_LENGTH)) 
            revert Tape__InvalidTapeModel('decodeTapeMetadata');
        model.decodeTapeMetadata("");
    }
    
    function _checkMethodExists(address implementation, bytes memory methodBytes, uint256 minLength) private view returns (bool) {
        (bool success, bytes memory data) = implementation.staticcall(methodBytes);
        return success && data.length > minLength;
    }

    function validateBondParams(uint128 newMaxSupply, uint256 maxSteps, uint128[] memory stepRangesMax, uint128[] memory stepCoefficients) pure public {
        if (stepRangesMax.length == 0 || stepRangesMax.length > maxSteps) revert Tape__InvalidBondParams('INVALID_STEP_LENGTH');
        if (stepCoefficients.length != stepRangesMax.length) revert Tape__InvalidBondParams('STEP_LENGTH_DO_NOT_MATCH');
        // Last value or the rangeTo must be the same as the maxSupply
        if (stepRangesMax[stepRangesMax.length - 1] != newMaxSupply) revert Tape__InvalidBondParams('MAX_SUPPLY_MISMATCH');
    }

    function getCurrentStep(uint256 currentSupply, TapeBond memory bond) public pure returns (uint256)  {
        for(uint256 i = 0; i < bond.steps.length; ++i) {
            if (currentSupply <= bond.steps[i].rangeMax) {
                return i;
            }
        }
        revert Tape__InvalidCurrentSupply(); // can never happen
    }

    function getCurrencyAmoutToMintTokens(uint256 tokensToMint, TapeBond memory bond) public pure
        returns (uint256 currencyAmount, uint256 finalPrice) {
        if (tokensToMint == 0) revert Tape__InvalidAmount();
        
        BondingCurveStep[] memory steps = bond.steps;

        uint256 currentSupply = bond.currentSupply;

        if (currentSupply + tokensToMint > bond.steps[bond.steps.length - 1].rangeMax) revert Tape__ExceedSupply();

        uint256 tokensLeft = tokensToMint;
        uint256 currencyAmountToBond;
        uint256 supplyLeft;
        uint256 priceAfter = bond.currentPrice;
        for (uint256 i = getCurrentStep(currentSupply, bond); i < steps.length; ++i) {
            BondingCurveStep memory step = steps[i];
            supplyLeft = step.rangeMax - currentSupply;

            if (supplyLeft < tokensLeft) {
                if(supplyLeft == 0) continue;

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

        if (currencyAmountToBond == 0 || tokensLeft > 0) revert Tape__InvalidAmount();

        finalPrice = priceAfter;
        currencyAmount = currencyAmountToBond;
    }
    
    function getCurrencyAmoutForBurningTokens(uint256 tokensToBurn, TapeBond memory bond) public pure
        returns (uint256 currencyAmount, uint256 finalPrice) {

        if (tokensToBurn == 0) revert Tape__InvalidAmount();
        
        BondingCurveStep[] memory steps = bond.steps;

        uint256 currentSupply = bond.currentSupply;

        if (tokensToBurn > currentSupply - bond.count.consumed) revert Tape__ExceedSupply();

        // uint256 multiFactor = 10**t.decimals();
        uint256 currencyAmountFromBond;
        uint256 tokensLeft = tokensToBurn;
        uint256 i = getCurrentStep(currentSupply, bond);
        uint256 priceAfter = bond.currentPrice;
        while (tokensLeft > 0) {
            BondingCurveStep memory step = steps[i];
            uint256 supplyLeft = i == 0 ? currentSupply : currentSupply - steps[i - 1].rangeMax;

            uint256 tokensToProcess = tokensLeft < supplyLeft ? tokensLeft : supplyLeft;
            // reserveFromBond += ((tokensToProcess * steps[i].price) / multiFactor);

            uint256 initialPrice = priceAfter;
            priceAfter = priceAfter - step.coefficient * (tokensToProcess - 1);
            currencyAmountFromBond += Math.ceilDiv((tokensToProcess) * (initialPrice + priceAfter), 2);

            tokensLeft -= tokensToProcess;
            currentSupply -= tokensToProcess;

            if (i == 0 && tokensToProcess == supplyLeft) priceAfter = 0;
            else priceAfter -= step.coefficient;

            if (i > 0) --i;
        }

        if (currencyAmountFromBond == 0 || tokensLeft > 0) revert Tape__InvalidAmount();

        finalPrice = priceAfter;
        currencyAmount = currencyAmountFromBond;
    }

    function getCurrencyAmoutForConsumingTokens(uint256 tokensToConsume, TapeBond memory bond) public pure
        returns (uint256 currencyAmount, uint256 finalPrice) {
        if (tokensToConsume == 0) revert Tape__InvalidAmount();
        
        BondingCurveStep[] memory steps = bond.steps;

        uint256 currentConsumed = bond.count.consumed;

        if (currentConsumed + tokensToConsume > bond.currentSupply) revert Tape__ExceedSupply();

        uint256 tokensLeft = tokensToConsume;
        uint256 currencyAmountToBond;
        uint256 supplyLeft;
        uint256 priceAfter = bond.consumePrice;
        for (uint256 i = getCurrentStep(currentConsumed, bond); i < steps.length; ++i) {
            BondingCurveStep memory step = steps[i];
            supplyLeft = step.rangeMax - currentConsumed;

            if (supplyLeft < tokensLeft) {
                if(supplyLeft == 0) continue;

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

        if (currencyAmountToBond == 0 || tokensLeft > 0) revert Tape__InvalidAmount();

        finalPrice = priceAfter;
        currencyAmount = currencyAmountToBond;
    }
    
}