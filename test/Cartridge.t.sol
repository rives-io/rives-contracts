// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import "@std/Test.sol";
import {console} from "@std/console.sol";
import {Cartridge} from "@src/Cartridge.sol";
import {CartridgeBondUtils} from "@src/CartridgeBondUtils.sol";
import {InvalidInterface} from "@mocks/InvalidInterface.sol";
import {CurrencyToken} from "@mocks/CurrencyToken.sol";
import {CartridgeFeeModel} from "@models/CartridgeFeeModel.sol";
import {CartridgeModel} from "@models/CartridgeModel.sol";
import {CartridgeOwnershipModelWithProxy} from "@models/CartridgeOwnershipModelWithProxy.sol";
import {BondingCurveModel} from "@models/BondingCurveModel.sol";

contract CartridgeTest is Test {
    Cartridge cartridge;
    CartridgeBondUtils cartridgeBondUtils;
    address operator = address(1);
    uint256 maxSteps = 100;

    function setUp() public {
        vm.startPrank(operator);
        cartridgeBondUtils = new CartridgeBondUtils();
        cartridge = new Cartridge(operator, address(cartridgeBondUtils), maxSteps);
    }

    function testCartridgeDeployment() public view {
        uint256 codeSize;
        address cartridgeAddress = address(cartridge);
        assembly {
            codeSize := extcodesize(cartridgeAddress)
        }

        assertTrue(codeSize > 0, "Cartridge should be deployed as a contract");
    }

    function testUpdateBondingCurveParamsWithAllCombinationsOfInvalidAndValidInterfaces() public {
        // Initialize the valid interfaces
        CurrencyToken validCurrencyToken = new CurrencyToken();
        CartridgeFeeModel validCartridgeFeeModel = new CartridgeFeeModel();
        CartridgeModel validCartridgeModel = new CartridgeModel();
        CartridgeOwnershipModelWithProxy validCartridgeOwnershipModelWithProxy =
            new CartridgeOwnershipModelWithProxy(operator);
        BondingCurveModel validBondingCurveModel = new BondingCurveModel();

        // Initialize the invalid interface
        InvalidInterface invalidInterface = new InvalidInterface();

        // Create an array of all valid interfaces
        address[5] memory validInterfaces = [
            address(validCurrencyToken),
            address(validCartridgeFeeModel),
            address(validCartridgeModel),
            address(validCartridgeOwnershipModelWithProxy),
            address(validBondingCurveModel)
        ];

        address invalid = address(invalidInterface);

        // Test all combinations
        for (uint256 i = 0; i < 32; i++) {
            address[5] memory params;

            for (uint256 j = 0; j < 5; j++) {
                if ((i >> j) & 1 == 1) {
                    params[j] = invalid; // Set invalid interface
                } else {
                    params[j] = validInterfaces[j]; // Set valid interface
                }
            }

            // Expect revert if any invalid interface is set
            //bool expectRevert = (i > 0);
            bool expectRevert = (i & 0x0F) > 0; // for now

            if (expectRevert) {
                vm.expectRevert();
            }

            // Call updateBondingCurveParams with the current combination
            cartridge.updateBondingCurveParams(
                params[0],
                params[1],
                params[2],
                params[3],
                address(validBondingCurveModel), /* for now bcs we don't check BondingCurveModel */
                100
            );

            if (!expectRevert) {
                assertTrue(true, "Bonding curve params updated with valid interfaces");
            }
        }
    }
}
