// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, ResourceIdInstance, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { WorldContextProviderLib } from "@latticexyz/world/src/WorldContext.sol";

import { Systems } from "@latticexyz/world/src/codegen/index.sol";

import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { IWorld } from "../codegen/world/IWorld.sol";

import "@latticexyz/world/src/worldResourceTypes.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

// import { DappAddressNamespace, NamespaceDappAddress, NamespaceSubscriptions, NamespaceDependencies, 
import { DappAddressNamespace, NamespaceDappAddress } from "../codegen/index.sol";
import { ICartesiDApp } from "@cartesi/rollups/contracts/dapp/ICartesiDApp.sol";
// import "@cartesi/rollups/contracts/inputs/IInputBox.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DappSystem is System {
  using WorldResourceIdInstance for ResourceId;
  error DappSystem__InvalidOwner();
  error DappSystem__InvalidResource();
  error DappSystem__InvalidDapp();
  // error DappSystem__ArrayError();
  error DappSystem__InvalidPayload();

  function addInput(address _dapp, bytes calldata _payload) public payable returns (bytes32) {
    if (_payload.length < 4) revert DappSystem__InvalidPayload();

    // get namespace system from db by dapp address
    bytes32 dappResourceIdbytes = DappAddressNamespace.get(_dapp);
    if (dappResourceIdbytes == 0x0) revert DappSystem__InvalidResource();

    ResourceId dappSystemResourceId = ResourceId.wrap(dappResourceIdbytes);

    ResourceId inputSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "InputSystem");

    bytes memory returnData = IWorld(_world()).call(
      inputSystem,
      abi.encodeWithSignature("prepareInput(address,uint256,bytes)",
        _msgSender(), _msgValue(), _payload));

    // add msg sender bytes in between
    bytes memory _proxiedPayload = abi.encodePacked(_payload[:4],_msgSender(),_payload[4:]);

    returnData = IWorld(_world()).call(
      inputSystem,
      abi.encodeWithSignature("addInputToCartesiInputBox(bytes32,bytes)", dappSystemResourceId, _proxiedPayload));

    return bytes32(returnData);
  }

  function setNamespaceSystem(address _dapp, ResourceId systemResource) public {

    // check namespace owner
    AccessControl.requireOwner(systemResource, _msgSender());
    if (NamespaceOwner.get(systemResource.getNamespaceId()) != _msgSender()) revert DappSystem__InvalidOwner();

    // comment for nonodo
    // check dapp owner
    if (Ownable(_dapp).owner() != _msgSender()) revert DappSystem__InvalidOwner();

    // check dapp is dapp (checking only get template hash)
    (bool success, bytes memory data) = _dapp.staticcall(abi.encodeWithSignature("getTemplateHash()"));
    if (!success || data.length != 32) revert DappSystem__InvalidDapp();
    // comment for nonodo/devnet
    if (ICartesiDApp(_dapp).getTemplateHash() == bytes32(0)) revert DappSystem__InvalidDapp();

    DappAddressNamespace.set(_dapp, ResourceId.unwrap(systemResource));
    NamespaceDappAddress.set(ResourceId.unwrap(systemResource), _dapp);
  }


}
