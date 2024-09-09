// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title IAdminSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IAdminSystem {
  error AdminSystem__InvalidOwner();
  error AdminSystem__InvalidParams();
  error AdminSystem__InvalidModel();

  function core__setInputBoxAddress(address _inputBox) external;

  function core__setCartridgeAssetAddress(address _cartridgeAsset) external;

  function core__setTapeAssetAddress(address _tapeAsset) external;

  function core__setRegisteredModel(address modelAddress, bool active) external;

  function core__setCartridgeInsertionModel(address modelAddress, bytes calldata config) external;
}
