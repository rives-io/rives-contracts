// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";
import "@cartesi/rollups/contracts/library/LibOutputValidation.sol";
import "@interfaces/ITapeFeeModel.sol";
import "@interfaces/ITapeModel.sol";
import "@interfaces/IOwnershipModel.sol";
import "@interfaces/IBondingCurveModel.sol";
import "./TapeBondUtils.sol";
import "./BondUtils.sol";

contract Tape is ERC1155, Ownable {
    error Tape__NotFound();
    error Tape__InvalidOwner();
    error Tape__InvalidUser();
    error Tape__InvalidDapp();
    error Tape__InvalidTape(string reason);
    error Tape__SlippageLimitExceeded();
    error Tape__InsufficientFunds();
    error Tape__ChangeError();
    error Tape__InvalidParams();

    struct UserAccount {
        address max;
        mapping(address => uint256) tokenBalance;
    }

    // Constants
    uint256 private immutable MAX_STEPS;

    // Default parameters
    IBondingCurveModel.BondingCurveStep[] public bondingCurveSteps;
    address public currencyTokenAddress;
    address public feeModelAddress;
    address public tapeModelAddress;
    address public tapeBondUtilsAddress;
    address public tapeOwnershipModelAddress;
    address public tapeBondingCurveModelAddress;
    uint256 public maxSupply;
    address protocolWallet;

    // Tapes
    mapping(bytes32 => TapeBondUtils.TapeBond) public tapeBonds; // id -> tape
    bytes32[] public tapeBondsCreated; // ids

    // Accounts
    mapping(address => mapping(address => uint256)) public accounts; // user -> token -> amount

    // dapps
    mapping(address => bool) public dappAddresses; // user -> token -> amount

    // Constructor
    constructor(address ownerAddress, address newTapeBondUtilsAddress, uint256 maxSteps)
        Ownable(ownerAddress)
        ERC1155("")
    {
        protocolWallet = ownerAddress;
        MAX_STEPS = maxSteps;
        tapeBondUtilsAddress = newTapeBondUtilsAddress;
    }

    modifier _checkTapeBond(bytes32 id) {
        if (tapeBonds[id].bond.steps.length == 0) revert Tape__NotFound();
        _;
    }

    modifier _checkTapeOwner(bytes32 id) {
        if (!IOwnershipModel(tapeOwnershipModelAddress).checkOwner(_msgSender(), id)) revert Tape__InvalidOwner();
        _;
    }

    function _createTapeBond(
        bytes32 id,
        IBondingCurveModel.BondingCurveStep[] memory steps,
        bool creatorAllocation,
        address creator
    ) internal {
        if (tapeBonds[id].bond.steps.length == 0) {
            TapeBondUtils.TapeBond storage newTapeBond = tapeBonds[id];
            newTapeBond.feeModel = feeModelAddress;
            newTapeBond.bond.currencyToken = currencyTokenAddress;
            newTapeBond.tapeModel = tapeModelAddress;
            for (uint256 i = 0; i < steps.length; ++i) {
                newTapeBond.bond.steps.push(
                    IBondingCurveModel.BondingCurveStep({rangeMax: steps[i].rangeMax, coefficient: steps[i].coefficient})
                );
            }
            tapeBondsCreated.push(id);
            if (creatorAllocation) {
                // reserved for self
                if (newTapeBond.bond.steps.length < 2 || newTapeBond.bond.steps[0].coefficient != 0) {
                    revert Tape__InvalidParams();
                }
                _buyTapesInternal(creator, id, newTapeBond.bond.steps[0].rangeMax, 0, creatorAllocation);
            }
        }
    }

    // admin

    function _updateBondingCurveParams(
        address newCurrencyToken,
        address newFeeModel,
        address newTapeModel,
        address newTapeOwnershipModelAddress,
        address newTapeBondingCurveModelAddress,
        uint256 newMaxSupply
    ) internal {
        TapeBondUtils(tapeBondUtilsAddress).verifyCurrencyToken(newCurrencyToken);
        TapeBondUtils(tapeBondUtilsAddress).verifyFeeModel(newFeeModel);
        TapeBondUtils(tapeBondUtilsAddress).verifyTapeModel(newTapeModel);
        TapeBondUtils(tapeBondUtilsAddress).verifyOwnershipModel(newTapeOwnershipModelAddress);

        currencyTokenAddress = newCurrencyToken;
        feeModelAddress = newFeeModel;
        tapeModelAddress = newTapeModel;
        tapeOwnershipModelAddress = newTapeOwnershipModelAddress;
        tapeBondingCurveModelAddress = newTapeBondingCurveModelAddress;
        maxSupply = newMaxSupply;
    }

    function updateProtocolWallet(address newProtocolWallet) external {
        if (_msgSender() != protocolWallet) revert Tape__InvalidUser();
        protocolWallet = newProtocolWallet;
    }

    function setDapp(address dapp, bool active) external onlyOwner {
        if (dappAddresses[dapp]) revert Tape__InvalidDapp();

        dappAddresses[dapp] = active;
    }

    function updateBondingCurveParams(
        address newCurrencyToken,
        address newFeeModel,
        address newTapeModel,
        address newTapeOwnershipModelAddress,
        address newTapeBondingCurveModelAddress,
        uint256 newMaxSupply
    ) external onlyOwner {
        _updateBondingCurveParams(
            newCurrencyToken,
            newFeeModel,
            newTapeModel,
            newTapeOwnershipModelAddress,
            newTapeBondingCurveModelAddress,
            newMaxSupply
        );
    }

    function setURI(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }

    function changeTapeModel(bytes32 tapeId, address newTapeModel) external onlyOwner {
        if (tapeBonds[tapeId].bond.steps.length == 0) revert Tape__NotFound();
        if (tapeBonds[tapeId].tapeOutputData.length > 0) {
            revert Tape__InvalidTape("Tape already validated");
        }
        TapeBondUtils(tapeBondUtilsAddress).verifyTapeModel(newTapeModel);
        tapeBonds[tapeId].tapeModel = newTapeModel;
    }

    // Fees functions
    function _distributeFees(bytes32 tapeId, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee)
        internal
        returns (uint256, uint256, uint256)
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
                    ITapeFeeModel(bond.feeModel).getTapesRoyaltiesFeesDistribution(royaltiesFee, royaltyTapes.length)
                );
                if (royaltiesLeftover > 0) {
                    (royaltiesCOF, royaltiesTCF) = ITapeFeeModel(bond.feeModel).getRoyaltiesFees(royaltiesLeftover);
                }
            } else {
                (royaltiesCOF, royaltiesTCF) = ITapeFeeModel(bond.feeModel).getRoyaltiesFees(royaltiesFee);
            }

            if (bond.cartridgeOwner != address(0)) {
                accounts[bond.cartridgeOwner][bond.bond.currencyToken] += cartridgeOwnerFee + royaltiesTCF;
                emit BondUtils.Reward(
                    tapeId,
                    bond.cartridgeOwner,
                    bond.bond.currencyToken,
                    BondUtils.RewardType.CartridgeOwnerFee,
                    cartridgeOwnerFee
                );
                if (royaltiesTCF > 0) {
                    emit BondUtils.Reward(
                        tapeId,
                        bond.cartridgeOwner,
                        bond.bond.currencyToken,
                        BondUtils.RewardType.RoyaltyLeftover,
                        royaltiesTCF
                    );
                }
            } else {
                leftoverFees += cartridgeOwnerFee + royaltiesTCF;
            }

            if (bond.tapeCreator != address(0)) {
                accounts[bond.tapeCreator][bond.bond.currencyToken] += tapeCreatorFee + royaltiesCOF;
                emit BondUtils.Reward(
                    tapeId,
                    bond.tapeCreator,
                    bond.bond.currencyToken,
                    BondUtils.RewardType.TapeCreatorFee,
                    tapeCreatorFee
                );
                if (royaltiesCOF > 0) {
                    emit BondUtils.Reward(
                        tapeId,
                        bond.tapeCreator,
                        bond.bond.currencyToken,
                        BondUtils.RewardType.RoyaltyLeftover,
                        royaltiesCOF
                    );
                }
            } else {
                leftoverFees += tapeCreatorFee + royaltiesCOF;
            }
            if (leftoverFees > 0) {
                accounts[protocolWallet][bond.bond.currencyToken] += leftoverFees;
                emit BondUtils.Reward(
                    tapeId, protocolWallet, bond.bond.currencyToken, BondUtils.RewardType.ProtocolLeftover, leftoverFees
                );
            }
            return (0, 0, 0);
        }
        return (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);
    }

    function _distributeRoyaltiesFees(
        uint256 feesToDistribute,
        bytes32[] memory royaltiesTapes,
        uint256[] memory royaltiesFeesDistribution
    ) internal returns (uint256) {
        uint256 i;
        while (feesToDistribute > 0) {
            if (royaltiesTapes.length <= i) break;
            if (royaltiesFeesDistribution.length <= i) break;
            _transferTapeRoyaltiesFee(royaltiesTapes[i], royaltiesFeesDistribution[i]);
            feesToDistribute -= royaltiesFeesDistribution[i];
            i++;
        }
        return feesToDistribute;
    }

    function _transferTapeRoyaltiesFee(
        bytes32 tapeId,
        uint256 royaltiesFee //_checkTapeBond(tapeId)
    ) internal {
        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        // transfer fees
        if (bond.tapeOutputData.length > 0) {
            uint256 leftoverFees;
            (uint256 royaltiesCOF, uint256 royaltiesTCF) = ITapeFeeModel(bond.feeModel).getRoyaltiesFees(royaltiesFee);

            if (bond.cartridgeOwner != address(0)) {
                accounts[bond.cartridgeOwner][bond.bond.currencyToken] += royaltiesTCF;
                emit BondUtils.Reward(
                    tapeId,
                    bond.cartridgeOwner,
                    bond.bond.currencyToken,
                    BondUtils.RewardType.RoyaltyLeftover,
                    royaltiesTCF
                );
            } else {
                leftoverFees += royaltiesTCF;
            }

            if (bond.tapeCreator != address(0)) {
                accounts[bond.tapeCreator][bond.bond.currencyToken] += royaltiesCOF;
                emit BondUtils.Reward(
                    tapeId,
                    bond.tapeCreator,
                    bond.bond.currencyToken,
                    BondUtils.RewardType.RoyaltyLeftover,
                    royaltiesCOF
                );
            } else {
                leftoverFees += royaltiesCOF;
            }
            if (leftoverFees > 0) {
                accounts[protocolWallet][bond.bond.currencyToken] += leftoverFees;
                emit BondUtils.Reward(
                    tapeId, protocolWallet, bond.bond.currencyToken, BondUtils.RewardType.ProtocolLeftover, leftoverFees
                );
            }
        } else {
            bond.bond.unclaimed.royalties += royaltiesFee;
        }
    }

    function buyTapes(bytes32 tapeId, uint256 tapesToMint, uint256 maxCurrencyPrice)
        public
        payable
        _checkTapeBond(tapeId)
        returns (uint256 currencyCost)
    {
        return _buyTapesInternal(_msgSender(), tapeId, tapesToMint, maxCurrencyPrice, false);
    }

    // mint/buy and burn/sell main functions
    function _buyTapesInternal(
        address sender,
        bytes32 tapeId,
        uint256 tapesToMint,
        uint256 maxCurrencyPrice,
        bool creatorAllocation
    ) private _checkTapeBond(tapeId) returns (uint256 currencyCost) {
        // buy from bonding curve
        address payable user = payable(sender);

        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        (uint256 currencyAmount, uint256 finalPrice) =
            TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmountToMintTokens(tapesToMint, bond.bond);

        // fees
        uint256 protocolFee;
        uint256 cartridgeOwnerFee;
        uint256 tapeCreatorFee;
        uint256 royaltiesFee;
        if (!creatorAllocation || currencyAmount != 0 || bond.bond.steps[0].coefficient != 0) {
            // reserved for self
            (protocolFee, cartridgeOwnerFee, tapeCreatorFee, royaltiesFee) =
                ITapeFeeModel(bond.feeModel).getMintFees(tapesToMint, currencyAmount);
        }

        uint256 totalPrice = currencyAmount + protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee;

        if (totalPrice > maxCurrencyPrice) revert Tape__SlippageLimitExceeded();

        bond.bond.currencyBalance += currencyAmount;
        bond.bond.currentSupply += tapesToMint;
        bond.bond.count.minted += tapesToMint;
        bond.bond.currentPrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee) =
            _distributeFees(tapeId, cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);

        bond.bond.unclaimed.mint += tapeCreatorFee + cartridgeOwnerFee;
        bond.bond.unclaimed.undistributedRoyalties += royaltiesFee;
        accounts[protocolWallet][bond.bond.currencyToken] += protocolFee;

        // Transfer currency from the user
        if (bond.bond.currencyToken != address(0)) {
            if (!ERC20(bond.bond.currencyToken).transferFrom(user, address(this), totalPrice)) {
                revert Tape__ChangeError();
            }
        } else {
            if (msg.value < totalPrice) {
                revert Tape__InsufficientFunds();
            } else {
                if (msg.value > totalPrice) {
                    (bool sent,) = user.call{value: msg.value - totalPrice}("");
                    if (!sent) revert Tape__ChangeError();
                }
            }
        }

        emit BondUtils.Reward(
            tapeId, protocolWallet, bond.bond.currencyToken, BondUtils.RewardType.ProtocolFee, protocolFee
        );

        // Mint
        _mint(user, uint256(tapeId), tapesToMint, "");

        emit BondUtils.Buy(tapeId, user, tapesToMint, totalPrice);
        emit BondUtils.Bond(
            tapeId, bond.bond.currencyToken, bond.bond.currentPrice, bond.bond.currentSupply, bond.bond.currencyBalance
        );

        return totalPrice;
    }

    function sellTapes(bytes32 tapeId, uint256 tapesToBurn, uint256 minCurrencyRefund)
        external
        _checkTapeBond(tapeId)
        returns (uint256)
    {
        address payable user = payable(_msgSender());

        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        (uint256 currencyAmount, uint256 finalPrice) =
            TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmountForBurningTokens(tapesToBurn, bond.bond);

        // fees
        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) =
            ITapeFeeModel(bond.feeModel).getBurnFees(tapesToBurn, currencyAmount);

        if (protocolFee + cartridgeOwnerFee + tapeCreatorFee > currencyAmount) {
            revert Tape__InsufficientFunds();
        }

        uint256 totalRefund = currencyAmount - (protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee);

        if (totalRefund < minCurrencyRefund) {
            revert Tape__SlippageLimitExceeded();
        }

        // burn
        _burn(user, uint256(tapeId), tapesToBurn);

        // update balances
        bond.bond.currencyBalance -= currencyAmount;
        bond.bond.currentSupply -= tapesToBurn;
        bond.bond.count.burned += tapesToBurn;
        bond.bond.currentPrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee) =
            _distributeFees(tapeId, cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);

        bond.bond.unclaimed.burn += tapeCreatorFee + cartridgeOwnerFee;
        bond.bond.unclaimed.undistributedRoyalties += royaltiesFee;

        accounts[protocolWallet][bond.bond.currencyToken] += protocolFee;
        emit BondUtils.Reward(
            tapeId, protocolWallet, bond.bond.currencyToken, BondUtils.RewardType.ProtocolFee, protocolFee
        );

        // Transfer currency to the user
        if (bond.bond.currencyToken != address(0)) {
            if (!ERC20(bond.bond.currencyToken).transfer(user, totalRefund)) {
                revert Tape__ChangeError();
            }
        } else {
            (bool sent,) = user.call{value: totalRefund}("");
            if (!sent) revert Tape__ChangeError();
        }

        emit BondUtils.Sell(tapeId, user, tapesToBurn, totalRefund);
        emit BondUtils.Bond(
            tapeId, bond.bond.currencyToken, bond.bond.currentPrice, bond.bond.currentSupply, bond.bond.currencyBalance
        );

        return totalRefund;
    }

    function consumeTapes(bytes32 tapeId, uint256 tapesToConsume) external _checkTapeBond(tapeId) returns (uint256) {
        address user = _msgSender();

        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        (uint256 currencyAmount, uint256 finalPrice) =
            TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmountForConsumingTokens(tapesToConsume, bond.bond);

        // fees
        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) =
            ITapeFeeModel(bond.feeModel).getConsumeFees(currencyAmount);

        // burn
        _burn(user, uint256(tapeId), tapesToConsume);

        // update balances
        bond.bond.currentSupply -= tapesToConsume;
        bond.bond.currencyBalance -= currencyAmount;
        bond.bond.count.consumed += tapesToConsume;
        bond.bond.consumePrice = finalPrice;

        // transfer fees
        (cartridgeOwnerFee, tapeCreatorFee, royaltiesFee) =
            _distributeFees(tapeId, cartridgeOwnerFee, tapeCreatorFee, royaltiesFee);

        bond.bond.unclaimed.consume += tapeCreatorFee + cartridgeOwnerFee;
        bond.bond.unclaimed.undistributedRoyalties += royaltiesFee;

        accounts[protocolWallet][bond.bond.currencyToken] += protocolFee;
        emit BondUtils.Reward(
            tapeId, protocolWallet, bond.bond.currencyToken, BondUtils.RewardType.ProtocolFee, protocolFee
        );

        // Transfer currency from the user

        emit BondUtils.Consume(tapeId, user, tapesToConsume, currencyAmount);
        emit BondUtils.Bond(
            tapeId, bond.bond.currencyToken, bond.bond.currentPrice, bond.bond.currentSupply, bond.bond.currencyBalance
        );

        return currencyAmount;
    }

    function setTapeParams(
        bytes32 tapeId,
        uint256[] memory stepRangesMax,
        uint256[] memory stepCoefficients,
        bool creatorAllocation,
        address creator
    ) public _checkTapeOwner(tapeId) {
        IBondingCurveModel.BondingCurveStep[] memory steps = IBondingCurveModel(tapeBondingCurveModelAddress)
            .validateBondingCurve(tapeId, stepRangesMax, stepCoefficients, maxSupply);

        _createTapeBond(tapeId, steps, creatorAllocation, creator);
    }

    function validateTape(address dapp, bytes32 tapeId, bytes calldata _payload, Proof calldata _v)
        external
        returns (bytes32)
    {
        TapeBondUtils.TapeBond storage bond = tapeBonds[tapeId];

        if (bond.tapeOutputData.length != 0) {
            revert Tape__InvalidTape("already validated");
        }

        // verify dapp
        if (!dappAddresses[dapp]) revert Tape__InvalidDapp();

        // validate notice
        ICartesiDApp(dapp).validateNotice(_payload, _v);

        (bytes32 decodedTapeId, address cartridgeOwner, address tapeCreator) =
            ITapeModel(bond.tapeModel).decodeTapeUsers(_payload);

        if (tapeId != decodedTapeId) revert Tape__InvalidTape("tapeId");

        bond.cartridgeOwner = cartridgeOwner;
        bond.tapeCreator = tapeCreator;
        bond.tapeOutputData = _payload;

        uint256 cofToDistribute;
        uint256 tcfToDistribute;
        uint256 rfToDistribute = bond.bond.unclaimed.undistributedRoyalties;

        if (bond.bond.unclaimed.mint > 0) {
            (, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee,) =
                ITapeFeeModel(bond.feeModel).getMintFees(bond.bond.count.minted, bond.bond.unclaimed.mint);
            if (cartridgeOwnerFee + tapeCreatorFee > bond.bond.unclaimed.mint) {
                revert Tape__InvalidTape("unclaimedMintFees");
            }

            bond.bond.unclaimed.mint -= cartridgeOwnerFee + tapeCreatorFee;
            cofToDistribute += cartridgeOwnerFee;
            tcfToDistribute += tapeCreatorFee;
        }

        if (bond.bond.unclaimed.burn > 0) {
            (, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee,) =
                ITapeFeeModel(bond.feeModel).getBurnFees(bond.bond.count.burned, bond.bond.unclaimed.burn);
            if (cartridgeOwnerFee + tapeCreatorFee > bond.bond.unclaimed.burn) {
                revert Tape__InvalidTape("unclaimedBurnFees");
            }

            bond.bond.unclaimed.burn -= cartridgeOwnerFee + tapeCreatorFee;
            cofToDistribute += cartridgeOwnerFee;
            tcfToDistribute += tapeCreatorFee;
        }

        if (bond.bond.unclaimed.royalties > 0) {
            (uint256 cartridgeOwnerFee, uint256 tapeCreatorFee) =
                ITapeFeeModel(bond.feeModel).getRoyaltiesFees(bond.bond.unclaimed.royalties);
            if (cartridgeOwnerFee + tapeCreatorFee > bond.bond.unclaimed.royalties) {
                revert Tape__InvalidTape("unclaimedBurnFees");
            }

            bond.bond.unclaimed.royalties -= cartridgeOwnerFee + tapeCreatorFee;
            cofToDistribute += cartridgeOwnerFee;
            tcfToDistribute += tapeCreatorFee;
        }

        _distributeFees(tapeId, cofToDistribute, tcfToDistribute, rfToDistribute);

        uint256 leftover = bond.bond.unclaimed.mint + bond.bond.unclaimed.burn + bond.bond.unclaimed.royalties;
        if (leftover > 0) {
            accounts[protocolWallet][bond.bond.currencyToken] +=
                bond.bond.unclaimed.mint + bond.bond.unclaimed.burn + bond.bond.unclaimed.royalties;
            emit BondUtils.Reward(
                tapeId, protocolWallet, bond.bond.currencyToken, BondUtils.RewardType.ProtocolLeftover, leftover
            );
        }

        bond.bond.unclaimed.mint = 0;
        bond.bond.unclaimed.burn = 0;
        bond.bond.unclaimed.royalties = 0;
        bond.bond.unclaimed.undistributedRoyalties = 0;

        return tapeId;
    }

    // withdraw

    function withdrawBalance(address token, uint256 amount) external {
        address payable user = payable(_msgSender());
        if (accounts[user][token] < amount) {
            revert BondUtils.Bond__InvalidAmount();
        }
        accounts[user][token] -= amount;

        if (token != address(0)) {
            if (!ERC20(token).transfer(user, amount)) {
                revert Tape__ChangeError();
            }
        } else {
            (bool sent,) = user.call{value: amount}("");
            if (!sent) revert Tape__ChangeError();
        }
    }

    // Utility functions views

    function getCurrentBuyPrice(bytes32 tapeId, uint256 tokensToMint)
        external
        view
        returns (uint256, uint256, uint256)
    {
        if (tapeBonds[tapeId].bond.steps.length == 0) revert Tape__NotFound();
        TapeBondUtils.TapeBond memory bond = tapeBonds[tapeId];

        (uint256 currencyAmount, uint256 finalPrice) =
            TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmountToMintTokens(tokensToMint, bond.bond);

        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) =
            ITapeFeeModel(bond.feeModel).getMintFees(tokensToMint, currencyAmount);
        uint256 fees = protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee;

        return (currencyAmount + fees, fees, finalPrice);
    }

    function getCurrentSellPrice(bytes32 tapeId, uint256 tokensToBurn)
        external
        view
        returns (uint256, uint256, uint256)
    {
        if (tapeBonds[tapeId].bond.steps.length == 0) revert Tape__NotFound();
        TapeBondUtils.TapeBond memory bond = tapeBonds[tapeId];
        (uint256 currencyAmount, uint256 finalPrice) =
            TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmountForBurningTokens(tokensToBurn, bond.bond);

        (uint256 protocolFee, uint256 cartridgeOwnerFee, uint256 tapeCreatorFee, uint256 royaltiesFee) =
            ITapeFeeModel(bond.feeModel).getBurnFees(tokensToBurn, currencyAmount);
        uint256 fees = protocolFee + cartridgeOwnerFee + tapeCreatorFee + royaltiesFee;

        return (currencyAmount - fees, fees, finalPrice);
    }

    function getCurrentConsumePrice(bytes32 tapeId, uint256 tokensToConsume) external view returns (uint256, uint256) {
        if (tapeBonds[tapeId].bond.steps.length == 0) revert Tape__NotFound();
        TapeBondUtils.TapeBond memory bond = tapeBonds[tapeId];
        (uint256 currencyAmount, uint256 finalPrice) =
            TapeBondUtils(tapeBondUtilsAddress).getCurrencyAmountForConsumingTokens(tokensToConsume, bond.bond);
        return (currencyAmount, finalPrice);
    }

    function tapesCount() external view returns (uint256) {
        return tapeBondsCreated.length;
    }

    function totalTapes() external view returns (uint256) {
        uint256 total;
        for (uint256 i; i < tapeBondsCreated.length; ++i) {
            total +=
                tapeBonds[tapeBondsCreated[i]].bond.currentSupply - tapeBonds[tapeBondsCreated[i]].bond.count.consumed;
        }
        return total;
    }

    function exists(bytes32 tapeId) external view returns (bool) {
        return tapeBonds[tapeId].bond.steps.length != 0;
    }

    function maxTapeSupply(bytes32 tapeId) external view returns (uint256) {
        return tapeBonds[tapeId].bond.steps[tapeBonds[tapeId].bond.steps.length - 1].rangeMax;
    }

    function getTapeData(bytes32 tapeId)
        external
        view
        returns (bytes32, uint256, int256, bytes32, int256, bytes32, int256, bytes32, int256)
    {
        if (tapeBonds[tapeId].tapeOutputData.length == 0) {
            revert Tape__InvalidTape("tapeOutputData");
        }
        return ITapeModel(tapeBonds[tapeId].tapeModel).decodeTapeMetadata(tapeBonds[tapeId].tapeOutputData);
    }

    function tokenUri(uint256 tokenId) public view returns (string memory) {
        return
            string.concat(uri(tokenId), TapeBondUtils(tapeBondUtilsAddress).toHex(abi.encodePacked(bytes32(tokenId))));
    }
}
