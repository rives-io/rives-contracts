// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { InputBoxAddress, CartridgeAssetAddress, TapeAssetAddress } from "../codegen/index.sol";
import "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";

contract InfoSystem is System {
  
  function getInputBoxAddress() public view returns (address) {
    return InputBoxAddress.get();
  }

  function getCartridgeAssetAddress() public view returns (address) {
    return CartridgeAssetAddress.get();
  }

  function getTapeAssetAddress() public view returns (address) {
    return TapeAssetAddress.get();
  }

}
