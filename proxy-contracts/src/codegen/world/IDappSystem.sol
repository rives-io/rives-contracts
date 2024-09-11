// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

/**
 * @title IDappSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IDappSystem {
  error DappSystem__InvalidOwner();
  error DappSystem__InvalidResource();
  error DappSystem__InvalidDapp();
  error DappSystem__InvalidPayload();

  function core__addInput(address _dapp, bytes calldata _payload) external payable returns (bytes32);

  function core__setNamespaceSystem(address _dapp, ResourceId systemResource) external;
}