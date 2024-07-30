// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { DebugCounter } from "../src/codegen/index.sol";

contract DebugCounterTest is MudTest {
  function testWorldExists() public {
    uint256 codeSize;
    address addr = worldAddress;
    assembly {
      codeSize := extcodesize(addr)
    }
    assertTrue(codeSize > 0);
  }

  // function testDebugCounter() public {
  //   // Expect the DebugCounter to be 1 because it was incremented in the PostDeploy script.
  //   uint32 counter = DebugCounter.get();
  //   // assertEq(counter, 1);

  //   // Expect the counter to be 2 after calling increment.
  //   // IWorld(worldAddress).app__increment();
  //   // counter = DebugCounter.get();
  //   // assertEq(counter, 2);
  // }
}
