// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";
import "@cartesi/rollups/contracts/library/LibOutputValidation.sol";
import "./ICartridgeFeeModel.sol";
import "./ICartridgeModel.sol";
import "./IOwnershipModel.sol";
import "./IBondingCurveModel.sol";
import "./CartridgeBondUtils.sol";
import "./BondUtils.sol";

contract Cartridge is ERC1155, Ownable {
    error Cartridge__NotFound();
    error Cartridge__InvalidOwner();
    error Cartridge__InvalidUser();
    error Cartridge__InvalidDapp();
    error Cartridge__InvalidCartridge(string reason);
    error Cartridge__InvalidTransfer(string reason);
    error Cartridge__SlippageLimitExceeded();
    error Cartridge__InsufficientFunds();
    error Cartridge__ChangeError();

    struct UserAccount {
        address max;
        mapping (address => uint256) tokenBalance;
    }

    // Constants
    uint256 private immutable MAX_STEPS;

    // base URI
    // string private _baseURI = "";

    // Default parameters
    IBondingCurveModel.BondingCurveStep[] public bondingCurveSteps;
    address public currencyTokenAddress;
    address public feeModelAddress;
    address public cartridgeModelAddress;
    address public cartridgeBondUtilsAddress;
    address public cartridgeOwnershipModelAddress;
    address public cartridgeBondingCurveModelAddress;
    uint256 public maxSupply;
    uint256 public feeConfig;
    address protocolWallet;

    // Cartridges
    mapping (bytes32 => CartridgeBondUtils.CartridgeBond) public cartridgeBonds; // id -> cartridge
    bytes32[] public cartridgeBondsCreated; // ids

    // Accounts
    mapping (address => mapping (address => uint256)) public accounts; // user -> token -> amount

    // dapps
    mapping (address => bool) public dappAddresses; // user -> token -> amount
    // address[] public dappAddresses;

    // Constructor
    constructor(
        address newCartridgeBondUtilsAddress,
        uint256 maxSteps
        // address newProtocolWallet,
        // uint256 maxSteps,
        // address newCurrencyToken,
        // address newFeeModel,
        // address newCartridgeModel,
        // address newCartridgeOwnershipModelAddress,
        // address newCartridgeBondingCurveModelAddress,
        // address newCartridgeBondUtilsAddress,
        // uint256 newMaxSupply,
        // uint256[] memory stepRangesMax, 
        // uint256[] memory stepCoefficients
    ) Ownable(tx.origin) ERC1155("") {
        protocolWallet = tx.origin;

        MAX_STEPS = maxSteps;
        
        cartridgeBondUtilsAddress = newCartridgeBondUtilsAddress;
        
        // _updateBondingCurveParams(
        //     newCurrencyToken,
        //     newFeeModel,
        //     newCartridgeModel,
        //     newCartridgeOwnershipModelAddress,
        //     newCartridgeBondingCurveModelAddress,
        //     newMaxSupply,
        //     stepRangesMax, 
        //     stepCoefficients);
    }


    // create bond
    // modifier _checkAndCreateCartridgeBond(bytes32 id) {
    //     _createCartridgeBond(id);
    //     _;
    // }

    modifier _checkCartridgeBond(bytes32 id) {
        if(cartridgeBonds[id].bond.steps.length == 0) revert Cartridge__NotFound();
        _;
    }

    modifier _checkCartridgeOwner(bytes32 id) {
        if(!IOwnershipModel(cartridgeOwnershipModelAddress).checkOwner(msg.sender,id)) revert Cartridge__InvalidOwner();
        _;
    }

    // function _createCartridgeBond(bytes32 id) internal {
    //     if(cartridgeBonds[id].steps.length == 0) {
    //         CartridgeBondUtils.CartridgeBond storage newCartridgeBond = cartridgeBonds[id];
    //         newCartridgeBond.feeModel = feeModelAddress;
    //         newCartridgeBond.currencyToken = currencyTokenAddress;
    //         newCartridgeBond.cartridgeModel = cartridgeModelAddress;
    //         for (uint256 i = 0; i < bondingCurveSteps.length; ++i) {
    //             newCartridgeBond.steps.push(IBondingCurveModel.BondingCurveStep({
    //                 rangeMax: bondingCurveSteps[i].rangeMax,
    //                 coefficient: bondingCurveSteps[i].coefficient
    //             }));
    //         }
    //         cartridgeBondsCreated.push(id);
    //     }
    // }

    function _createCartridgeBond(bytes32 id, uint256 bondFeeConfig, IBondingCurveModel.BondingCurveStep[] memory steps, bool creatorAllocation) internal {
        if(cartridgeBonds[id].bond.steps.length == 0) {
            CartridgeBondUtils.CartridgeBond storage newCartridgeBond = cartridgeBonds[id];
            newCartridgeBond.feeModel = feeModelAddress;
            newCartridgeBond.feeConfig = bondFeeConfig;
            newCartridgeBond.bond.currencyToken = currencyTokenAddress;
            newCartridgeBond.cartridgeModel = cartridgeModelAddress;
            for (uint256 i = 0; i < steps.length; ++i) {
                newCartridgeBond.bond.steps.push(IBondingCurveModel.BondingCurveStep({
                    rangeMax: steps[i].rangeMax,
                    coefficient: steps[i].coefficient
                }));
            }
            cartridgeBondsCreated.push(id);
            if (creatorAllocation && newCartridgeBond.bond.steps[0].coefficient == 0) { // reserved for self
                buyCartridges(id,newCartridgeBond.bond.steps[0].rangeMax,0);
            }
        }
    }

    // admin

    function _updateBondingCurveParams(
        address newCurrencyToken,
        address newFeeModel,
        address newCartridgeModel,
        address newCartridgeOwnershipModelAddress,
        address newCartridgeBondingCurveModelAddress,
        uint256 newMaxSupply,
        uint256 newFeeConfig,
        uint256[] memory stepRangesMax, 
        uint256[] memory stepCoefficients) internal 
    {

        CartridgeBondUtils(cartridgeBondUtilsAddress).verifyCurrencyToken(newCurrencyToken);

        CartridgeBondUtils(cartridgeBondUtilsAddress).verifyFeeModel(newFeeModel);

        CartridgeBondUtils(cartridgeBondUtilsAddress).verifyCartridgeModel(newCartridgeModel);
        
        CartridgeBondUtils(cartridgeBondUtilsAddress).verifyOwnershipModel(newCartridgeOwnershipModelAddress);
        
        IBondingCurveModel(newCartridgeBondingCurveModelAddress).validateBondParams(MAX_STEPS,stepRangesMax,stepCoefficients);

        // BondingCurveStep[] bondingCurveSteps;
        
        // uint256 multiFactor = 10**IERC20Metadata(newCurrencyToken).decimals();

        delete bondingCurveSteps;

        IBondingCurveModel.BondingCurveStep[] memory steps = IBondingCurveModel(newCartridgeBondingCurveModelAddress).validateBondingCurve(bytes32(0),stepRangesMax,stepCoefficients,newMaxSupply);
        for (uint256 i = 0; i < steps.length; ++i) {
            bondingCurveSteps.push(IBondingCurveModel.BondingCurveStep({
                rangeMax: steps[i].rangeMax,
                coefficient: steps[i].coefficient
            }));
        }
        // for (uint256 i = 0; i < stepRangesMax.length; ++i) {
        //     uint256 stepRangeMax = stepRangesMax[i];
        //     uint256 stepCoefficient = stepCoefficients[i];

        //     if (stepRangeMax == 0) {
        //         revert CartridgeBondUtils.Cartridge__InvalidBondParams('STEP_CANNOT_BE_ZERO');
        //     } 
        //     // else if (stepCoefficient > 0 && stepRangeMax * stepCoefficient < multiFactor) {
        //     //     // To minimize rounding errors, the product of the range and coefficient must be at least multiFactor (1e18 for ERC20)
        //     //     revert Cartridge__InvalidBondParams('STEP_RANGE_OR_PRICE_TOO_SMALL');
        //     // }

        //     bondingCurveSteps.push(IBondingCurveModel.BondingCurveStep({
        //         rangeMax: uint256(stepRangeMax),
        //         coefficient: uint256(stepCoefficient)
        //     }));
        // }
        currencyTokenAddress = newCurrencyToken;

        feeModelAddress = newFeeModel;

        cartridgeModelAddress = newCartridgeModel;

        cartridgeOwnershipModelAddress = newCartridgeOwnershipModelAddress;

        cartridgeBondingCurveModelAddress = newCartridgeBondingCurveModelAddress;
        
        maxSupply = newMaxSupply;

        feeConfig = newFeeConfig;

    }

    function updateProtocolWallet(address newProtocolWallet) external {
        if(_msgSender() != protocolWallet) revert Cartridge__InvalidUser();
        protocolWallet = newProtocolWallet;
    }

    function addDapp(address dapp) external onlyOwner {
        if (dappAddresses[dapp]) revert Cartridge__InvalidDapp();
        
        dappAddresses[dapp] = true;
    }

    function updateBondingCurveParams(
        address newCurrencyToken,
        address newFeeModel,
        address newCartridgeModel,
        address newCartridgeOwnershipModelAddress,
        address newCartridgeBondingCurveModelAddress,
        uint256 newMaxSupply,
        uint256 newFeeConfig,
        uint256[] memory stepRangesMax, 
        uint256[] memory stepCoefficients) external onlyOwner {

        _updateBondingCurveParams(
            newCurrencyToken,
            newFeeModel,
            newCartridgeModel,
            newCartridgeOwnershipModelAddress,
            newCartridgeBondingCurveModelAddress,
            newMaxSupply,
            newFeeConfig,
            stepRangesMax, 
            stepCoefficients);
    }

    function setURI(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    // function setBaseURI(string memory baseURI) public onlyOwner {
    //     _baseURI = baseURI;
    // }

    function changeCartridgeModel(bytes32 cartridgeId, address newCartridgeModel) external onlyOwner {
        if (cartridgeBonds[cartridgeId].bond.steps.length == 0) revert Cartridge__NotFound();
        if (cartridgeBonds[cartridgeId].eventData.length > 0) revert Cartridge__InvalidCartridge('Cartridge already validated');
        CartridgeBondUtils(cartridgeBondUtilsAddress).verifyCartridgeModel(newCartridgeModel);
        cartridgeBonds[cartridgeId].cartridgeModel = newCartridgeModel;
    }

    // function updateCartridgeCreator(address token, address creator) external {
        // if (bond.creator != _msgSender()) revert
        // if (creator == address(0)) revert MCV2_Bond__InvalidCreatorAddress();
    // function updateCartridgeCartridgeOwner(address token, address owner) external {


    // Fees functions
    function _distributeFees(
        bytes32 tapeId, 
        uint256 cartridgeOwnerFee) 
        internal returns (uint256) 
    {
        CartridgeBondUtils.CartridgeBond storage bond = cartridgeBonds[tapeId];

        if (bond.eventData.length > 0) {
            uint256 leftoverFees;
            
            if (bond.cartridgeOwner != address(0)) {
                accounts[bond.cartridgeOwner][bond.bond.currencyToken] += cartridgeOwnerFee;
                emit BondUtils.Reward(tapeId,bond.cartridgeOwner,bond.bond.currencyToken,BondUtils.RewardType.CartridgeOwnerFee,cartridgeOwnerFee);
            } else {
                leftoverFees += cartridgeOwnerFee;
            }

            if (leftoverFees > 0) {
                accounts[protocolWallet][bond.bond.currencyToken] += leftoverFees;
                emit BondUtils.Reward(tapeId,protocolWallet,bond.bond.currencyToken,BondUtils.RewardType.ProtocolLeftover,leftoverFees);
            }
            return (0);
        }
        return (cartridgeOwnerFee);

    }

    // mint/buy and burn/sell main functions
    function buyCartridges(bytes32 cartridgeId, uint256 cartridgesToMint, uint256 maxCurrencyPrice) public _checkCartridgeBond(cartridgeId) payable returns (uint256 currencyCost) {
        // buy from bonding curve
        
        // if (receiver == address(0)) revert Cartridge__InvalidReceiver();
        address user = _msgSender();

        CartridgeBondUtils.CartridgeBond storage bond = cartridgeBonds[cartridgeId];

        (uint256 currencyAmount, uint256 finalPrice) = CartridgeBondUtils(cartridgeBondUtilsAddress).getCurrencyAmoutToMintTokens(cartridgesToMint, bond.bond);

        // fees
        uint256 protocolFee;
        uint256 cartridgeOwnerFee;
        if (bond.bond.steps[0].coefficient != 0) { // reserved for self
            (protocolFee,cartridgeOwnerFee) = ICartridgeFeeModel(bond.feeModel).getMintFees(bond.feeConfig, cartridgesToMint, currencyAmount);
        }

        uint256 totalPrice = currencyAmount + protocolFee + cartridgeOwnerFee;

        if (totalPrice > maxCurrencyPrice) revert Cartridge__SlippageLimitExceeded();

        // Transfer currency from the user
        if (bond.bond.currencyToken != address(0))
            ERC20(bond.bond.currencyToken).transferFrom(user, address(this), totalPrice);
        else {
            if (msg.value < totalPrice) revert Cartridge__InsufficientFunds();
            else if (msg.value > totalPrice) {
                (bool sent, ) = user.call{value: msg.value - totalPrice}("");
                if (!sent) revert Cartridge__ChangeError();
            }
        }
        
        // update balances
        bond.bond.currencyBalance += currencyAmount;
        bond.bond.currentSupply += cartridgesToMint;
        bond.bond.count.minted += cartridgesToMint;
        bond.bond.currentPrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee) = _distributeFees(cartridgeId, cartridgeOwnerFee);

        bond.bond.unclaimed.mint += cartridgeOwnerFee;
        accounts[protocolWallet][bond.bond.currencyToken] += protocolFee;
        emit BondUtils.Reward(cartridgeId,protocolWallet,bond.bond.currencyToken,BondUtils.RewardType.ProtocolFee,protocolFee);

        // Mint 
        _mint(user, uint256(cartridgeId), cartridgesToMint, "");

        emit BondUtils.Buy(cartridgeId, user, cartridgesToMint, totalPrice);
        emit BondUtils.Bond(cartridgeId, bond.bond.currencyToken, bond.bond.currentPrice, bond.bond.currentSupply,bond.bond.currencyBalance);

        return totalPrice;
    }

    function sellCartridges(bytes32 cartridgeId, uint256 cartridgesToBurn, uint256 minCurrencyRefund) external _checkCartridgeBond(cartridgeId) returns (uint256) {

        // if (receiver == address(0)) revert Cartridge__InvalidReceiver();
        address user = _msgSender();

        CartridgeBondUtils.CartridgeBond storage bond = cartridgeBonds[cartridgeId];

        (uint256 currencyAmount, uint256 finalPrice) = CartridgeBondUtils(cartridgeBondUtilsAddress).getCurrencyAmoutForBurningTokens(cartridgesToBurn, bond.bond);

        // fees
        (uint256 protocolFee, uint256 cartridgeOwnerFee) = ICartridgeFeeModel(bond.feeModel).getBurnFees(bond.feeConfig, cartridgesToBurn, currencyAmount);

        uint256 totalRefund = currencyAmount - (protocolFee + cartridgeOwnerFee);

        if (totalRefund < minCurrencyRefund) revert Cartridge__SlippageLimitExceeded();

        // burn
        _burn(user, uint256(cartridgeId), cartridgesToBurn);

        // update balances
        bond.bond.currencyBalance -= currencyAmount;
        bond.bond.currentSupply -= cartridgesToBurn;
        bond.bond.count.burned += cartridgesToBurn;
        bond.bond.currentPrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee) = _distributeFees(cartridgeId, cartridgeOwnerFee);

        bond.bond.unclaimed.burn += cartridgeOwnerFee;

        accounts[protocolWallet][bond.bond.currencyToken] += protocolFee;
        emit BondUtils.Reward(cartridgeId,protocolWallet,bond.bond.currencyToken,BondUtils.RewardType.ProtocolFee,protocolFee);

        // Transfer currency from the user
        if (bond.bond.currencyToken != address(0)) {
            ERC20(bond.bond.currencyToken).approve(address(this), totalRefund);
            ERC20(bond.bond.currencyToken).transferFrom(address(this), user, totalRefund);
        } else {
            (bool sent, ) = user.call{value: totalRefund}("");
            if (!sent) revert Cartridge__ChangeError();
        }

        emit BondUtils.Sell(cartridgeId, user, cartridgesToBurn, totalRefund);
        emit BondUtils.Bond(cartridgeId, bond.bond.currencyToken, bond.bond.currentPrice, bond.bond.currentSupply,bond.bond.currencyBalance);

        return totalRefund;
    }

    function consumeCartridges(bytes32 cartridgeId, uint256 cartridgesToConsume) external _checkCartridgeBond(cartridgeId) returns (uint256) {

        // if (receiver == address(0)) revert Cartridge__InvalidReceiver();
        address user = _msgSender();

        CartridgeBondUtils.CartridgeBond storage bond = cartridgeBonds[cartridgeId];

        (uint256 currencyAmount, uint256 finalPrice) = CartridgeBondUtils(cartridgeBondUtilsAddress).getCurrencyAmoutForConsumingTokens(cartridgesToConsume, bond.bond);

        // fees
        (uint256 protocolFee, uint256 cartridgeOwnerFee) = ICartridgeFeeModel(bond.feeModel).getConsumeFees(bond.feeConfig, currencyAmount);
        if (protocolFee + cartridgeOwnerFee != currencyAmount) revert Cartridge__InsufficientFunds();

        // burn
        _burn(user, uint256(cartridgeId), cartridgesToConsume);

        // update balances
        bond.bond.currentSupply -= cartridgesToConsume;
        bond.bond.currencyBalance -= currencyAmount;
        bond.bond.count.consumed += cartridgesToConsume;
        bond.bond.consumePrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee) = _distributeFees(cartridgeId, cartridgeOwnerFee);

        bond.bond.unclaimed.consume += cartridgeOwnerFee;

        accounts[protocolWallet][bond.bond.currencyToken] += protocolFee;
        emit BondUtils.Reward(cartridgeId,protocolWallet,bond.bond.currencyToken,BondUtils.RewardType.ProtocolFee,protocolFee);

        // Transfer currency from the user

        emit BondUtils.Consume(cartridgeId, user, cartridgesToConsume, currencyAmount);
        emit BondUtils.Bond(cartridgeId, bond.bond.currencyToken, bond.bond.currentPrice, bond.bond.currentSupply,bond.bond.currencyBalance);

        return currencyAmount;
    }

    function setCartridgeParamsCustom(
        bytes32 cartridgeId,
        uint256 bondFeeConfig,
        uint256[] memory stepRangesMax, 
        uint256[] memory stepCoefficients,
        bool creatorAllocation) public _checkCartridgeOwner(cartridgeId) {

        IBondingCurveModel.BondingCurveStep[] memory steps = IBondingCurveModel(cartridgeBondingCurveModelAddress).validateBondingCurve(cartridgeId,stepRangesMax,stepCoefficients,maxSupply);

        _createCartridgeBond(cartridgeId,bondFeeConfig,steps,creatorAllocation);
    }

    function setCartridgeParams(bytes32 cartridgeId) public _checkCartridgeOwner(cartridgeId) {
        _createCartridgeBond(cartridgeId,feeConfig,bondingCurveSteps,false);
    }

    function validateCartridgeCustom(
        address dapp,
        bytes32 cartridgeId,
        bytes calldata _payload,
        Proof calldata _v,
        uint256 bondFeeConfig,
        uint256[] memory stepRangesMax, 
        uint256[] memory stepCoefficients,
        bool creatorAllocation) external returns (bytes32) {

        setCartridgeParamsCustom(cartridgeId,bondFeeConfig,stepRangesMax,stepCoefficients,creatorAllocation);

        return _validateCartridge(dapp,cartridgeId,_payload,_v);
    }

    function validateCartridge(
        address dapp,
        bytes32 cartridgeId,
        bytes calldata _payload,
        Proof calldata _v) external returns (bytes32) {

        setCartridgeParams(cartridgeId);

        return _validateCartridge(dapp,cartridgeId,_payload,_v);
    }

    function _validateCartridge(
        address dapp,
        bytes32 cartridgeId,
        bytes calldata _payload,
        Proof calldata _v) internal returns (bytes32) {

        CartridgeBondUtils.CartridgeBond storage bond = cartridgeBonds[cartridgeId];

        if (bond.eventData.length != 0) revert Cartridge__InvalidCartridge('already validated');

        // verify dapp
        if (!dappAddresses[dapp]) revert Cartridge__InvalidDapp();

        // validate notice
        ICartesiDApp(dapp).validateNotice(_payload,_v);

        (bytes32 decodedCartridgeId,address cartridgeOwner) = ICartridgeModel(bond.cartridgeModel).decodeCartridgeUser(_payload);

        if (cartridgeId != decodedCartridgeId) revert Cartridge__InvalidCartridge('cartridgeId');

        (, uint timestamp, ,) = ICartridgeModel(bond.cartridgeModel).decodeCartridgeMetadata(_payload);

        bond.cartridgeOwner = cartridgeOwner;
        bond.eventData = _payload;
        bond.lastUpdate = timestamp;

        uint256 cofToDistribute;

        if (bond.bond.unclaimed.mint > 0) {
            (, uint256 cartridgeOwnerFee) = ICartridgeFeeModel(bond.feeModel).getMintFees(bond.feeConfig, bond.bond.count.minted, bond.bond.unclaimed.mint);
            if (cartridgeOwnerFee > bond.bond.unclaimed.mint) revert Cartridge__InvalidCartridge('unclaimedMintFees');

            bond.bond.unclaimed.mint -= cartridgeOwnerFee;
            cofToDistribute += cartridgeOwnerFee;
        }

        if (bond.bond.unclaimed.burn > 0) {
            (, uint256 cartridgeOwnerFee) = ICartridgeFeeModel(bond.feeModel).getBurnFees(bond.feeConfig, bond.bond.count.burned, bond.bond.unclaimed.burn);
            if (cartridgeOwnerFee > bond.bond.unclaimed.burn) revert Cartridge__InvalidCartridge('unclaimedBurnFees');

            bond.bond.unclaimed.burn -= cartridgeOwnerFee;
            cofToDistribute += cartridgeOwnerFee;
        }

        _distributeFees(cartridgeId, cofToDistribute);

        uint256 leftover = bond.bond.unclaimed.mint + bond.bond.unclaimed.burn;
        if (leftover > 0) {
            accounts[protocolWallet][bond.bond.currencyToken] += bond.bond.unclaimed.mint + bond.bond.unclaimed.burn;
            emit BondUtils.Reward(cartridgeId,protocolWallet,bond.bond.currencyToken,BondUtils.RewardType.ProtocolLeftover,leftover);
        }

        bond.bond.unclaimed.mint = 0;
        bond.bond.unclaimed.burn = 0;
        bond.bond.unclaimed.undistributedRoyalties = 0;

        return cartridgeId;
    }

    function validateTransferCartridge(
        address dapp,
        bytes32 cartridgeId,
        bytes calldata _payload,
        Proof calldata _v) internal returns (bytes32) {

        CartridgeBondUtils.CartridgeBond storage bond = cartridgeBonds[cartridgeId];

        if (bond.eventData.length == 0) revert Cartridge__InvalidCartridge('not validated');

        // verify dapp
        if (!dappAddresses[dapp]) revert Cartridge__InvalidDapp();

        // validate notice
        ICartesiDApp(dapp).validateNotice(_payload,_v);

        (bytes32 decodedCartridgeId,address cartridgeOwner) = ICartridgeModel(bond.cartridgeModel).decodeCartridgeUser(_payload);

        if (cartridgeId != decodedCartridgeId) revert Cartridge__InvalidTransfer('cartridgeId');

        (, uint timestamp, ,) = ICartridgeModel(bond.cartridgeModel).decodeCartridgeMetadata(_payload);

        if (bond.lastUpdate >= timestamp) revert Cartridge__InvalidTransfer('timestamp');

        bond.cartridgeOwner = cartridgeOwner;
        bond.eventData = _payload;
        bond.lastUpdate = timestamp;

        return cartridgeId;
    }

    // withdraw

    function withdrawBalance(address token, uint256 amount) external {
        address user = _msgSender();
        if (accounts[user][token] < amount) revert BondUtils.Bond__InvalidAmount();
        accounts[user][token] -= amount;

        if (token != address(0)) {
            ERC20(token).approve(address(this), amount);
            ERC20(token).transferFrom(address(this), user, amount);
        } else {
            (bool sent, ) = user.call{value: amount}("");
            if (!sent) revert Cartridge__ChangeError();
        }

    }


    // Utility functions views

    // function balance() external view returns (uint256) {
    //     return address(this).balance;
    // }

    function getCurrentBuyPrice(bytes32 cartridgeId, uint256 tokensToMint) external view returns (uint256, uint256, uint256) {
        if (cartridgeBonds[cartridgeId].bond.steps.length == 0) revert Cartridge__NotFound();
        CartridgeBondUtils.CartridgeBond memory bond = cartridgeBonds[cartridgeId];
        
        // CartridgeBondUtils.CartridgeBond memory bond = cartridgeBonds[cartridgeId].steps.length != 0 ? 
        //     cartridgeBonds[cartridgeId] : 
        //     CartridgeBondUtils.CartridgeBond({
        //         feeModel:feeModelAddress,
        //         cartridgeModel:cartridgeModelAddress,
        //         currencyToken:currencyTokenAddress,
        //         steps:bondingCurveSteps,
        //         currencyBalance:0,
        //         currentSupply:0,
        //         currentPrice:0,
        //         consumePrice:0,
        //         unclaimed:CartridgeBondUtils.UnclaimedFees(0,0,0,0,0),
        //         // unclaimedMintFees:0,
        //         // unclaimedBurnFees:0,
        //         // unclaimedRoyaltiesFees:0,
        //         // undistributedRoyaltiesFees:0,
        //         // totalMinted:0,
        //         // totalBurned:0,
        //         count:CartridgeBondUtils.BondCount(0,0,0),
        //         // addresses: [address(0),address(0)],
        //         cartridgeOwner:address(0),
        //         cartridgeCreator:address(0),
        //         cartridgeOutputData:""
        //     });

        (uint256 currencyAmount, uint256 finalPrice) = CartridgeBondUtils(cartridgeBondUtilsAddress).getCurrencyAmoutToMintTokens(tokensToMint, bond.bond);
        
        (uint256 protocolFee, uint256 cartridgeOwnerFee) = ICartridgeFeeModel(bond.feeModel).getMintFees(bond.feeConfig, tokensToMint, currencyAmount);
        uint256 fees = protocolFee + cartridgeOwnerFee;

        return (currencyAmount + fees, fees, finalPrice);
    }

    function getCurrentSellPrice(bytes32 cartridgeId, uint256 tokensToBurn) external view returns (uint256, uint256, uint256) {
        if (cartridgeBonds[cartridgeId].bond.steps.length == 0) revert Cartridge__NotFound();
        CartridgeBondUtils.CartridgeBond memory bond = cartridgeBonds[cartridgeId];
        (uint256 currencyAmount, uint256 finalPrice) = CartridgeBondUtils(cartridgeBondUtilsAddress).getCurrencyAmoutForBurningTokens(tokensToBurn, bond.bond);
        
        (uint256 protocolFee, uint256 cartridgeOwnerFee) = ICartridgeFeeModel(bond.feeModel).getBurnFees(bond.feeConfig, tokensToBurn, currencyAmount);
        uint256 fees = protocolFee + cartridgeOwnerFee;

        return (currencyAmount - fees, fees, finalPrice);
    }

    function getCurrentConsumePrice(bytes32 cartridgeId, uint256 tokensToConsume) external view returns (uint256, uint256) {
        if (cartridgeBonds[cartridgeId].bond.steps.length == 0) revert Cartridge__NotFound();
        CartridgeBondUtils.CartridgeBond memory bond = cartridgeBonds[cartridgeId];
        (uint256 currencyAmount, uint256 finalPrice) = CartridgeBondUtils(cartridgeBondUtilsAddress).getCurrencyAmoutForConsumingTokens(tokensToConsume, bond.bond);
        return (currencyAmount, finalPrice);
    }

    function cartridgesCount() external view returns (uint256) {
        return cartridgeBondsCreated.length;
    }

    function totalCartridges() external view returns (uint256) {
        uint256 total;
        for (uint256 i; i < cartridgeBondsCreated.length; ++i) {
            total += cartridgeBonds[cartridgeBondsCreated[i]].bond.currentSupply - cartridgeBonds[cartridgeBondsCreated[i]].bond.count.consumed;
        }
        return total;
    }

    function exists(bytes32 cartridgeId) external view returns (bool) {
        return cartridgeBonds[cartridgeId].bond.steps.length != 0;
    }

    // function getSteps(bytes32 cartridgeId) external view returns (BondingCurveStep[] memory) {
    //     return cartridgeBonds[cartridgeId].steps;
    // }

    function maxCartridgeSupply(bytes32 cartridgeId) external view returns (uint256) {
        return cartridgeBonds[cartridgeId].bond.steps[cartridgeBonds[cartridgeId].bond.steps.length - 1].rangeMax;
    }

    function getCartridgeData(bytes32 cartridgeId) external view returns (bytes32, uint, bytes32, int) {
        if (cartridgeBonds[cartridgeId].eventData.length == 0) revert Cartridge__InvalidCartridge("cartridgeOutputData");
        return ICartridgeModel(cartridgeBonds[cartridgeId].cartridgeModel).decodeCartridgeMetadata(cartridgeBonds[cartridgeId].eventData);
    }

    // function uri(uint256 tokenId) public view override returns (string memory) {
    //     return uri(bytes32(tokenId));
    // }

    // function uri(bytes32 tokenId) public view returns (string memory) {
    //     return string.concat(_baseURI, CartridgeBondUtils(cartridgeBondUtilsAddress).toHex(abi.encodePacked(tokenId)));
    // }

}