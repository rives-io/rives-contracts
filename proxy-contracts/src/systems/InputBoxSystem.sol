// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import "@cartesi/rollups/contracts/inputs/IInputBox.sol";

import { InputBoxAddress } from "../codegen/index.sol";

contract InputBoxSystem is System {
  error InputBoxSystem__NoInputBox();
  function proxyAddInput(address _dapp, bytes calldata _payload) public returns (bytes32) {
    address inputBoxAddress = InputBoxAddress.get();
    if (inputBoxAddress == address(0)) revert InputBoxSystem__NoInputBox();

    return IInputBox(inputBoxAddress).addInput(_dapp, _payload);
  }

}
