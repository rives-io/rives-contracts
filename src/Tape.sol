// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";
import "@cartesi/rollups/contracts/library/LibOutputValidation.sol";
import "./ITapeFeeModel.sol";
import "./ITapeModel.sol";
import "./ITapeOwnershipModel.sol";
import "./TapeBondUtils.sol";

contract Tape is ERC1155, Ownable {
    struct UserAccount {
        address max;
        mapping (address => uint256) tokenBalance;
    }

    // Constants
    uint256 private immutable MAX_STEPS;

    // base URI
    // string private _baseURI = "";

    // Default parameters
    TapeBondUtils.BondingCurveStep[] public bondingCurveSteps;
    address public currencyTokenAddress;
    address public feeModelAddress;
    address public tapeModelAddress;
    address public tapeBondUtilsAddress;
    address public tapeOwnershipAddress;
    uint128 public maxSupply;
    address protocolWallet;

    // Tapes
    mapping (bytes32 => TapeBondUtils.TapeBond) public tapeBonds; // id -> tape
    bytes32[] public tapeBondsCreated; // ids

    // Accounts
    mapping (address => mapping (address => uint256)) public accounts; // user -> token -> amount

    // dapps
    address[] public dappAddresses;

    // Constructor
    constructor(
        address newProtocolWallet,
        uint256 maxSteps,
        address newCurrencyToken,
        address newFeeModel,
        address newTapeModel,
        address newTapeBondUtilsAddress,
        address newTapeOwnershipAddress,
        uint128 newMaxSupply,
        uint128[] memory stepRangesMax, 
        uint128[] memory stepCoefficients
    ) Ownable(msg.sender) ERC1155("") {
        protocolWallet = newProtocolWallet;

        MAX_STEPS = maxSteps;
        
        tapeBondUtilsAddress = newTapeBondUtilsAddress;
        
        _updateBondingCurveParams(
            newCurrencyToken,
            newFeeModel,
            newTapeModel,
            newTapeOwnershipAddress,
            newMaxSupply,
            stepRangesMax, 
            stepCoefficients);
    }


    // create bond
    // modifier _checkAndCreateTapeBond(bytes32 id) {
    //     _createTapeBond(id);
    //     _;
    // }

    modifier _checkTapeBond(bytes32 id) {
        if(tapeBonds[id].steps.length == 0) revert TapeBondUtils.Tape__NotFound();
        _;
    }

    modifier _checkTapeOwner(bytes32 id) {
        if(!ITapeOwnershipModel(tapeOwnershipAddress).checkOwner(msg.sender,id)) revert TapeBondUtils.Tape__InvalidOwner();
        _;
    }

    // function _createTapeBond(bytes32 id) internal {
    //     if(tapeBonds[id].steps.length == 0) {
    //         TapeBondUtils.TapeBond storage newTapeBond = tapeBonds[id];
    //         newTapeBond.feeModel = feeModelAddress;
    //         newTapeBond.currencyToken = currencyTokenAddress;
    //         newTapeBond.tapeModel = tapeModelAddress;
    //         for (uint256 i = 0; i < bondingCurveSteps.length; ++i) {
    //             newTapeBond.steps.push(TapeBondUtils.BondingCurveStep({
    //                 rangeMax: bondingCurveSteps[i].rangeMax,
    //                 coefficient: bondingCurveSteps[i].coefficient
    //             }));
    //         }
    //         tapeBondsCreated.push(id);
    //     }
    // }

    function _createTapeBond(bytes32 id, TapeBondUtils.BondingCurveStep[] memory steps) internal {
        if(tapeBonds[id].steps.length == 0) {
            TapeBondUtils.TapeBond storage newTapeBond = tapeBonds[id];
            newTapeBond.feeModel = feeModelAddress;
            newTapeBond.currencyToken = currencyTokenAddress;
            newTapeBond.tapeModel = tapeModelAddress;
            for (uint256 i = 0; i < steps.length; ++i) {
                newTapeBond.steps.push(TapeBondUtils.BondingCurveStep({
                    rangeMax: steps[i].rangeMax,
                    coefficient: steps[i].coefficient
                }));
            }
            tapeBondsCreated.push(id);
            if (newTapeBond.steps[0].coefficient == 0) { // reserved for self
                buyTapes(id,newTapeBond.steps[0].rangeMax,0);
            }
        }
    }

    // admin

    function _updateBondingCurveParams(
        address newCurrencyToken,
        address newFeeModel,
        address newTapeModel,
        address newTapeOwnershipAddress,
        uint128 newMaxSupply,
        uint128[] memory stepRangesMax, 
        uint128[] memory stepCoefficients) internal 
    {

        TapeBondUtils(tapeBondUtilsAddress).verifyCurrencyToken(newCurrencyToken);

        TapeBondUtils(tapeBondUtilsAddress).verifyFeeModel(newFeeModel);

        TapeBondUtils(tapeBondUtilsAddress).verifyTapeModel(newTapeModel);
        
        TapeBondUtils(tapeBondUtilsAddress).verifyTapeOwnershipModel(newTapeOwnershipAddress);
        
        TapeBondUtils(tapeBondUtilsAddress).validateBondParams(MAX_STEPS,stepRangesMax,stepCoefficients);

        // BondingCurveStep[] bondingCurveSteps;
        
        // uint256 multiFactor = 10**IERC20Metadata(newCurrencyToken).decimals();

        delete bondingCurveSteps;

        TapeBondUtils.BondingCurveStep[] memory steps = TapeBondUtils(tapeBondUtilsAddress).validateBondingCurve(stepRangesMax,stepCoefficients,newMaxSupply);
        for (uint256 i = 0; i < steps.length; ++i) {
            bondingCurveSteps.push(TapeBondUtils.BondingCurveStep({
                rangeMax: steps[i].rangeMax,
                coefficient: steps[i].coefficient
            }));
        }
        // for (uint256 i = 0; i < stepRangesMax.length; ++i) {
        //     uint256 stepRangeMax = stepRangesMax[i];
        //     uint256 stepCoefficient = stepCoefficients[i];

        //     if (stepRangeMax == 0) {
        //         revert TapeBondUtils.Tape__InvalidBondParams('STEP_CANNOT_BE_ZERO');
        //     } 
        //     // else if (stepCoefficient > 0 && stepRangeMax * stepCoefficient < multiFactor) {
        //     //     // To minimize rounding errors, the product of the range and coefficient must be at least multiFactor (1e18 for ERC20)
        //     //     revert Tape__InvalidBondParams('STEP_RANGE_OR_PRICE_TOO_SMALL');
        //     // }

        //     bondingCurveSteps.push(TapeBondUtils.BondingCurveStep({
        //         rangeMax: uint128(stepRangeMax),
        //         coefficient: uint128(stepCoefficient)
        //     }));
        // }
        currencyTokenAddress = newCurrencyToken;

        feeModelAddress = newFeeModel;

        tapeModelAddress = newTapeModel;

        tapeOwnershipAddress = newTapeOwnershipAddress;
        
        maxSupply = newMaxSupply;

    }

    function updateProtocolWallet(address newProtocolWallet) external {
        if(_msgSender() != protocolWallet) revert TapeBondUtils.Tape__InvalidUser();
        protocolWallet = newProtocolWallet;
    }

    function addDapp(address dapp) external onlyOwner {
        uint256 i;
        for (; i < dappAddresses.length; ++i) {
            if (dappAddresses[i] == dapp) break;
        }
        if (i != dappAddresses.length) revert TapeBondUtils.Tape__InvalidDapp();
        dappAddresses.push(dapp);
    }

    function updateBondingCurveParams(
        address newCurrencyToken,
        address newFeeModel,
        address newTapeModel,
        address newTapeOwnershipAddress,
        uint128 newMaxSupply,
        uint128[] memory stepRangesMax, 
        uint128[] memory stepCoefficients) external onlyOwner {

        _updateBondingCurveParams(
            newCurrencyToken,
            newFeeModel,
            newTapeModel,
            newTapeOwnershipAddress,
            newMaxSupply,
            stepRangesMax, 
            stepCoefficients);
    }

    // function setURI(string calldata newUri) external onlyOwner {
    //     _setURI(newUri);
    // }

    // function setBaseURI(string memory baseURI) public onlyOwner {
    //     _baseURI = baseURI;
    // }

    function changeTapeModel(bytes32 tapeId, address newTapeModel) external onlyOwner {
        if (tapeBonds[tapeId].steps.length == 0) revert TapeBondUtils.Tape__NotFound();
        if (tapeBonds[tapeId].tapeOutputData.length > 0) revert TapeBondUtils.Tape__InvalidTape('Tape already validated');
        TapeBondUtils(tapeBondUtilsAddress).verifyTapeModel(newTapeModel);
        tapeBonds[tapeId].tapeModel = newTapeModel;
    }

    // function updateTapeCreator(address token, address creator) external {
        // if (bond.creator != _msgSender()) revert
        // if (creator == address(0)) revert MCV2_Bond__InvalidCreatorAddress();
    // function updateTapeCartridgeOwner(address token, address owner) external {


    // Fees functions
    function _distributeFees(
        bytes32 tapeId, 
        uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) 
        internal returns (uint256,uint256,uint256) 
    {
        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        if (bond.tapeOutputData.length > 0) {
            uint256 leftoverFees;
            uint256 royaltiesCOF;
            uint256 royaltiesTCF;
            bytes32[] memory royaltyTapes = ITapeModel(bond.tapeModel).getRoyaltiesTapes(bond.tapeOutputData);
            if (royaltyTapes.length > 0) {
                
                // distribute fees
                uint256 royaltiesLeftover = _distributeRoyaltiesFees(
                    royaltiesFee,
                    royaltyTapes,
                    ITapeFeeModel(bond.feeModel).getTapesRoyaltiesFeesDistribution(royaltiesFee,royaltyTapes.length)
                );
                if (royaltiesLeftover > 0) {
                    (royaltiesCOF,royaltiesTCF) = ITapeFeeModel(bond.feeModel).getRoyaltiesFees(royaltiesLeftover);
                }
            } else {
                (royaltiesCOF,royaltiesTCF) = ITapeFeeModel(bond.feeModel).getRoyaltiesFees(royaltiesFee);
            }

            if (bond.cartridgeOwner != address(0)) {
                accounts[bond.cartridgeOwner][bond.currencyToken] += cartridgeOwnerFee + royaltiesTCF;
                emit TapeBondUtils.Reward(tapeId,bond.cartridgeOwner,bond.currencyToken,TapeBondUtils.RewardType.CartridgeOwnerFee,cartridgeOwnerFee);
                if (royaltiesTCF > 0)
                    emit TapeBondUtils.Reward(tapeId,bond.cartridgeOwner,bond.currencyToken,TapeBondUtils.RewardType.RoyaltyLeftover,royaltiesTCF);
            } else {
                leftoverFees += cartridgeOwnerFee + royaltiesTCF;
            }

            if (bond.tapeCreator != address(0)) {
                accounts[bond.tapeCreator][bond.currencyToken] += tapeCreatorFee + royaltiesCOF;
                emit TapeBondUtils.Reward(tapeId,bond.tapeCreator,bond.currencyToken,TapeBondUtils.RewardType.TapeCreatorFee,tapeCreatorFee);
                if (royaltiesCOF > 0)
                    emit TapeBondUtils.Reward(tapeId,bond.tapeCreator,bond.currencyToken,TapeBondUtils.RewardType.RoyaltyLeftover,royaltiesCOF);
            } else {
                leftoverFees += tapeCreatorFee + royaltiesCOF;
            }
            if (leftoverFees > 0) {
                accounts[protocolWallet][bond.currencyToken] += leftoverFees;
                emit TapeBondUtils.Reward(tapeId,protocolWallet,bond.currencyToken,TapeBondUtils.RewardType.ProtocolLeftover,leftoverFees);
            }
            return (0,0,0);
        }
        return (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);

    }

    function _distributeRoyaltiesFees(uint256 feesToDistribute, bytes32[] memory royaltiesTapes, uint256[] memory royaltiesFeesDistribution) internal returns (uint256) {
        uint256 i;
        while (feesToDistribute > 0) {
            if (royaltiesTapes.length <= i) break;
            if (royaltiesFeesDistribution.length <= i) break;
            _transferTapeRoyaltiesFee(royaltiesTapes[i],royaltiesFeesDistribution[i]);
            feesToDistribute -= royaltiesFeesDistribution[i];
            i++;
        }
        return feesToDistribute;
    }

    function _transferTapeRoyaltiesFee(bytes32 tapeId, uint256 royaltiesFee) internal _checkTapeBond(tapeId) {
        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        // transfer fees
        if (bond.tapeOutputData.length > 0) {
            uint256 leftoverFees;
            (uint256 royaltiesCOF,uint256 royaltiesTCF) = ITapeFeeModel(bond.feeModel).getRoyaltiesFees(royaltiesFee);

            if (bond.cartridgeOwner != address(0)) {
                accounts[bond.cartridgeOwner][bond.currencyToken] += royaltiesTCF;
                emit TapeBondUtils.Reward(tapeId,bond.cartridgeOwner,bond.currencyToken,TapeBondUtils.RewardType.RoyaltyLeftover,royaltiesTCF);
            } else {
                leftoverFees += royaltiesTCF;
            }

            if (bond.tapeCreator != address(0)) {
                accounts[bond.tapeCreator][bond.currencyToken] += royaltiesCOF;
                emit TapeBondUtils.Reward(tapeId,bond.tapeCreator,bond.currencyToken,TapeBondUtils.RewardType.RoyaltyLeftover,royaltiesCOF);
            } else {
                leftoverFees += royaltiesCOF;
            }
            if (leftoverFees > 0) {
                accounts[protocolWallet][bond.currencyToken] += leftoverFees;
                emit TapeBondUtils.Reward(tapeId,protocolWallet,bond.currencyToken,TapeBondUtils.RewardType.ProtocolLeftover,leftoverFees);
            }

        } else {
            bond.unclaimed.royalties += royaltiesFee;
        }
    }


    // mint/buy and burn/sell main functions
    function buyTapes(bytes32 tapeId, uint256 tapesToMint, uint256 maxCurrencyPrice) public _checkTapeBond(tapeId) payable returns (uint256 currencyCost) {
        // buy from bonding curve
        
        // if (receiver == address(0)) revert Tape__InvalidReceiver();
        address user = _msgSender();

        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        (uint256 currencyAmount, uint256 finalPrice) = TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmoutToMintTokens(tapesToMint, bond);

        // fees
        uint256 protocolFee;
        uint256 cartridgeOwnerFee;
        uint256 tapeCreatorFee;
        uint256 royaltiesFee;
        if (bond.steps[0].coefficient != 0) { // reserved for self
            (protocolFee,cartridgeOwnerFee, tapeCreatorFee,royaltiesFee) = ITapeFeeModel(bond.feeModel).getMintFees(tapesToMint, currencyAmount);
        }

        uint256 totalPrice = currencyAmount + protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee;

        if (totalPrice > maxCurrencyPrice) revert TapeBondUtils.Tape__SlippageLimitExceeded();

        // Transfer currency from the user
        if (bond.currencyToken != address(0))
            ERC20(bond.currencyToken).transferFrom(user, address(this), totalPrice);
        else {
            if (msg.value < totalPrice) revert TapeBondUtils.Tape__InsufficientFunds();
            else if (msg.value > totalPrice) {
                (bool sent, ) = user.call{value: msg.value - totalPrice}("");
                if (!sent) revert TapeBondUtils.Tape__ChangeError();
            }
        }
        
        // update balances
        bond.currencyBalance += currencyAmount;
        bond.currentSupply += tapesToMint;
        bond.count.minted += tapesToMint;
        bond.currentPrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee) = _distributeFees(tapeId, cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);

        bond.unclaimed.mint += tapeCreatorFee + cartridgeOwnerFee;
        bond.unclaimed.undistributedRoyalties += royaltiesFee;
        accounts[protocolWallet][bond.currencyToken] += protocolFee;
        emit TapeBondUtils.Reward(tapeId,protocolWallet,bond.currencyToken,TapeBondUtils.RewardType.ProtocolFee,protocolFee);

        // Mint 
        _mint(user, uint256(tapeId), tapesToMint, "");

        emit TapeBondUtils.Buy(tapeId, user, tapesToMint, totalPrice);
        emit TapeBondUtils.Tape(tapeId, bond.currencyToken, bond.currentPrice, bond.currentSupply,bond.currencyBalance);

        return totalPrice;
    }

    function sellTapes(bytes32 tapeId, uint256 tapesToBurn, uint256 minCurrencyRefund) external _checkTapeBond(tapeId) returns (uint256) {

        // if (receiver == address(0)) revert Tape__InvalidReceiver();
        address user = _msgSender();

        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        (uint256 currencyAmount, uint256 finalPrice) = TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmoutForBurningTokens(tapesToBurn, bond);

        // fees
        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) = ITapeFeeModel(bond.feeModel).getBurnFees(tapesToBurn, currencyAmount);

        uint256 totalRefund = currencyAmount - (protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee);

        if (totalRefund < minCurrencyRefund) revert TapeBondUtils.Tape__SlippageLimitExceeded();

        // burn
        _burn(user, uint256(tapeId), tapesToBurn);

        // update balances
        bond.currencyBalance -= currencyAmount;
        bond.currentSupply -= tapesToBurn;
        bond.count.burned += tapesToBurn;
        bond.currentPrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee) = _distributeFees(tapeId, cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);

        bond.unclaimed.burn += tapeCreatorFee + cartridgeOwnerFee;
        bond.unclaimed.undistributedRoyalties += royaltiesFee;

        accounts[protocolWallet][bond.currencyToken] += protocolFee;
        emit TapeBondUtils.Reward(tapeId,protocolWallet,bond.currencyToken,TapeBondUtils.RewardType.ProtocolFee,protocolFee);

        // Transfer currency from the user
        if (bond.currencyToken != address(0)) {
            ERC20(bond.currencyToken).approve(address(this), totalRefund);
            ERC20(bond.currencyToken).transferFrom(address(this), user, totalRefund);
        } else {
            (bool sent, ) = user.call{value: totalRefund}("");
            if (!sent) revert TapeBondUtils.Tape__ChangeError();
        }

        emit TapeBondUtils.Sell(tapeId, user, tapesToBurn, totalRefund);
        emit TapeBondUtils.Tape(tapeId, bond.currencyToken, bond.currentPrice, bond.currentSupply,bond.currencyBalance);

        return totalRefund;
    }

    function consumeTapes(bytes32 tapeId, uint256 tapesToConsume) external _checkTapeBond(tapeId) returns (uint256) {

        // if (receiver == address(0)) revert Tape__InvalidReceiver();
        address user = _msgSender();

        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        (uint256 currencyAmount, uint256 finalPrice) = TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmoutForConsumingTokens(tapesToConsume, bond);

        // fees
        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) = ITapeFeeModel(bond.feeModel).getConsumeFees(currencyAmount);

        // burn
        _burn(user, uint256(tapeId), tapesToConsume);

        // update balances
        bond.currentSupply -= tapesToConsume;
        bond.currencyBalance -= currencyAmount;
        bond.count.consumed += tapesToConsume;
        bond.consumePrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee) = _distributeFees(tapeId, cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);

        bond.unclaimed.consume += tapeCreatorFee + cartridgeOwnerFee;
        bond.unclaimed.undistributedRoyalties += royaltiesFee;

        accounts[protocolWallet][bond.currencyToken] += protocolFee;
        emit TapeBondUtils.Reward(tapeId,protocolWallet,bond.currencyToken,TapeBondUtils.RewardType.ProtocolFee,protocolFee);

        // Transfer currency from the user

        emit TapeBondUtils.Consume(tapeId, user, tapesToConsume, currencyAmount);
        emit TapeBondUtils.Tape(tapeId, bond.currencyToken, bond.currentPrice, bond.currentSupply,bond.currencyBalance);

        return currencyAmount;
    }

    function setTapeParamsCustom(
        bytes32 tapeId,
        uint128[] memory stepRangesMax, 
        uint128[] memory stepCoefficients) public _checkTapeOwner(tapeId) {

        TapeBondUtils.BondingCurveStep[] memory steps = TapeBondUtils(tapeBondUtilsAddress).validateBondingCurve(stepRangesMax,stepCoefficients,maxSupply);

        _createTapeBond(tapeId,steps);
    }

    function setTapeParams(bytes32 tapeId) public _checkTapeOwner(tapeId) {
        _createTapeBond(tapeId,bondingCurveSteps);
    }

    function validateTapeCustom(
        address dapp,
        bytes32 tapeId,
        bytes calldata _payload,
        Proof calldata _v,
        uint128[] memory stepRangesMax, 
        uint128[] memory stepCoefficients) external returns (bytes32) {

        setTapeParamsCustom(tapeId,stepRangesMax,stepCoefficients);

        return _validateTape(dapp,tapeId,_payload,_v);
    }

    function validateTape(
        address dapp,
        bytes32 tapeId,
        bytes calldata _payload,
        Proof calldata _v) external returns (bytes32) {

        setTapeParams(tapeId);

        return _validateTape(dapp,tapeId,_payload,_v);
    }

    function _validateTape(
        address dapp,
        bytes32 tapeId,
        bytes calldata _payload,
        Proof calldata _v) internal returns (bytes32) {

        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        if (bond.tapeOutputData.length != 0) revert TapeBondUtils.Tape__InvalidTape('already validated');

        // verify dapp
        uint256 i;
        for (; i < dappAddresses.length; ++i) {
            if (dappAddresses[i] == dapp) break;
        }
        if (i == dappAddresses.length) revert TapeBondUtils.Tape__InvalidDapp();

        // validate notice
        ICartesiDApp(dapp).validateNotice(_payload,_v);

        (bytes32 decodedTapeId,address cartridgeOwner,address tapeCreator) = ITapeModel(bond.tapeModel).decodeTapeUsers(_payload);

        if (tapeId != decodedTapeId) revert TapeBondUtils.Tape__InvalidTape('tapeId');

        bond.cartridgeOwner = cartridgeOwner;
        bond.tapeCreator = tapeCreator;
        bond.tapeOutputData = _payload;

        uint256 cofToDistribute;
        uint256 tcfToDistribute;
        uint256 rfToDistribute = bond.unclaimed.undistributedRoyalties;

        if (bond.unclaimed.mint > 0) {
            (, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee,) = ITapeFeeModel(bond.feeModel).getMintFees(bond.count.minted, bond.unclaimed.mint);
            if (cartridgeOwnerFee + tapeCreatorFee > bond.unclaimed.mint) revert TapeBondUtils.Tape__InvalidTape('unclaimedMintFees');

            bond.unclaimed.mint -= cartridgeOwnerFee + tapeCreatorFee;
            cofToDistribute += cartridgeOwnerFee;
            tcfToDistribute += tapeCreatorFee;
        }

        if (bond.unclaimed.burn > 0) {
            (, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee,) = ITapeFeeModel(bond.feeModel).getBurnFees(bond.count.burned, bond.unclaimed.burn);
            if (cartridgeOwnerFee + tapeCreatorFee > bond.unclaimed.burn) revert TapeBondUtils.Tape__InvalidTape('unclaimedBurnFees');

            bond.unclaimed.burn -= cartridgeOwnerFee + tapeCreatorFee;
            cofToDistribute += cartridgeOwnerFee;
            tcfToDistribute += tapeCreatorFee;
        }

        if (bond.unclaimed.royalties > 0) {
            (uint256 cartridgeOwnerFee, uint256 tapeCreatorFee) = ITapeFeeModel(bond.feeModel).getRoyaltiesFees(bond.unclaimed.royalties);
            if (cartridgeOwnerFee + tapeCreatorFee > bond.unclaimed.royalties) revert TapeBondUtils.Tape__InvalidTape('unclaimedBurnFees');

            bond.unclaimed.royalties -= cartridgeOwnerFee + tapeCreatorFee;
            cofToDistribute += cartridgeOwnerFee;
            tcfToDistribute += tapeCreatorFee;
        }

        _distributeFees(tapeId, cofToDistribute, tcfToDistribute, rfToDistribute);

        uint256 leftover = bond.unclaimed.mint + bond.unclaimed.burn + bond.unclaimed.royalties;
        if (leftover > 0) {
            accounts[protocolWallet][bond.currencyToken] += bond.unclaimed.mint + bond.unclaimed.burn + bond.unclaimed.royalties;
            emit TapeBondUtils.Reward(tapeId,protocolWallet,bond.currencyToken,TapeBondUtils.RewardType.ProtocolLeftover,leftover);
        }

        bond.unclaimed.mint = 0;
        bond.unclaimed.burn = 0;
        bond.unclaimed.royalties = 0;
        bond.unclaimed.undistributedRoyalties = 0;

        return tapeId;
    }


    // withdraw

    function withdrawBalance(address token, uint256 amount) external {
        address user = _msgSender();
        if (accounts[user][token] < amount) revert TapeBondUtils.Tape__InvalidAmount();
        accounts[user][token] -= amount;

        if (token != address(0)) {
            ERC20(token).approve(address(this), amount);
            ERC20(token).transferFrom(address(this), user, amount);
        } else {
            (bool sent, ) = user.call{value: amount}("");
            if (!sent) revert TapeBondUtils.Tape__ChangeError();
        }

    }


    // Utility functions views

    // function balance() external view returns (uint256) {
    //     return address(this).balance;
    // }

    function getCurrentBuyPrice(bytes32 tapeId, uint256 tokensToMint) external view returns (uint256, uint256, uint256) {
        if (tapeBonds[tapeId].steps.length == 0) revert TapeBondUtils.Tape__NotFound();
        TapeBondUtils.TapeBond memory bond = tapeBonds[tapeId];
        
        // TapeBondUtils.TapeBond memory bond = tapeBonds[tapeId].steps.length != 0 ? 
        //     tapeBonds[tapeId] : 
        //     TapeBondUtils.TapeBond({
        //         feeModel:feeModelAddress,
        //         tapeModel:tapeModelAddress,
        //         currencyToken:currencyTokenAddress,
        //         steps:bondingCurveSteps,
        //         currencyBalance:0,
        //         currentSupply:0,
        //         currentPrice:0,
        //         consumePrice:0,
        //         unclaimed:TapeBondUtils.UnclaimedFees(0,0,0,0,0),
        //         // unclaimedMintFees:0,
        //         // unclaimedBurnFees:0,
        //         // unclaimedRoyaltiesFees:0,
        //         // undistributedRoyaltiesFees:0,
        //         // totalMinted:0,
        //         // totalBurned:0,
        //         count:TapeBondUtils.BondCount(0,0,0),
        //         // addresses: [address(0),address(0)],
        //         cartridgeOwner:address(0),
        //         tapeCreator:address(0),
        //         tapeOutputData:""
        //     });

        (uint256 currencyAmount, uint256 finalPrice) = TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmoutToMintTokens(tokensToMint, bond);
        
        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) = ITapeFeeModel(bond.feeModel).getMintFees(tokensToMint, currencyAmount);
        uint256 fees = protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee;

        return (currencyAmount + fees, fees, finalPrice);
    }

    function getCurrentSellPrice(bytes32 tapeId, uint256 tokensToBurn) external view returns (uint256, uint256, uint256) {
        if (tapeBonds[tapeId].steps.length == 0) revert TapeBondUtils.Tape__NotFound();
        TapeBondUtils.TapeBond memory bond = tapeBonds[tapeId];
        (uint256 currencyAmount, uint256 finalPrice) = TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmoutForBurningTokens(tokensToBurn, bond);
        
        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) = ITapeFeeModel(bond.feeModel).getBurnFees(tokensToBurn, currencyAmount);
        uint256 fees = protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee;

        return (currencyAmount - fees, fees, finalPrice);
    }

    function getCurrentConsumePrice(bytes32 tapeId, uint256 tokensToConsume) external view returns (uint256, uint256) {
        if (tapeBonds[tapeId].steps.length == 0) revert TapeBondUtils.Tape__NotFound();
        TapeBondUtils.TapeBond memory bond = tapeBonds[tapeId];
        (uint256 currencyAmount, uint256 finalPrice) = TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmoutForConsumingTokens(tokensToConsume, bond);
        return (currencyAmount, finalPrice);
    }

    function tapesCount() external view returns (uint256) {
        return tapeBondsCreated.length;
    }

    function totalTapes() external view returns (uint256) {
        uint256 total;
        for (uint256 i; i < tapeBondsCreated.length; ++i) {
            total += tapeBonds[tapeBondsCreated[i]].currentSupply - tapeBonds[tapeBondsCreated[i]].count.consumed;
        }
        return total;
    }

    function exists(bytes32 tapeId) external view returns (bool) {
        return tapeBonds[tapeId].steps.length != 0;
    }

    // function getSteps(bytes32 tapeId) external view returns (BondingCurveStep[] memory) {
    //     return tapeBonds[tapeId].steps;
    // }

    function maxTapeSupply(bytes32 tapeId) external view returns (uint128) {
        return tapeBonds[tapeId].steps[tapeBonds[tapeId].steps.length - 1].rangeMax;
    }

    function getTapeData(bytes32 tapeId) external view returns (bytes32, bytes32, int, bytes32, int, bytes32, int) {
        if (tapeBonds[tapeId].tapeOutputData.length == 0) revert TapeBondUtils.Tape__InvalidTape("tapeOutputData");
        return ITapeModel(tapeBonds[tapeId].tapeModel).decodeTapeMetadata(tapeBonds[tapeId].tapeOutputData);
    }

    // function uri(uint256 tokenId) public view override returns (string memory) {
    //     return uri(bytes32(tokenId));
    // }

    // function uri(bytes32 tokenId) public view returns (string memory) {
    //     return string.concat(_baseURI, TapeBondUtils(tapeBondUtilsAddress).toHex(abi.encodePacked(tokenId)));
    // }

}