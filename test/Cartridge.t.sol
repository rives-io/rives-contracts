// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

import "@std/Test.sol";
import {Cartridge} from "../src/Cartridge.sol";
import {CartridgeBondUtils} from "../src/CartridgeBondUtils.sol";

contract CartridgeTest is Test {
    Cartridge cartridge;
    CartridgeBondUtils cartridgeBondUtils;
    address operator = address(1);
    uint256 maxSteps = 100;

    function setUp() public {
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
}
