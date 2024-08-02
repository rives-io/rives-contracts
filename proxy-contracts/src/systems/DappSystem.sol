// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId, ResourceIdInstance, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";

import { SystemCallData } from "@latticexyz/world/src/modules/init/types.sol";
 
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";

import { IWorld } from "../codegen/world/IWorld.sol";

import "@latticexyz/world/src/worldResourceTypes.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";

// import { DappAddressNamespace, NamespaceDappAddress, NamespaceSubscriptions, NamespaceDependencies, 
import { DappAddressNamespace, NamespaceDappAddress, DebugCounter, DappMessagesDebug} from "../codegen/index.sol";
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

  function addInput(address _dapp, bytes calldata _payload) public returns (bytes32) {
    if (_payload.length < 4) revert DappSystem__InvalidPayload();

    // get namespace system from db by dapp address
    bytes32 dappResourceIdbytes = DappAddressNamespace.get(_dapp);
    if (dappResourceIdbytes == 0x0) revert DappSystem__InvalidResource();

    ResourceId dappSystemResourceId = ResourceId.wrap(dappResourceIdbytes);

    // // DEBUG
    // uint32 c = DebugCounter.get();

    // DappMessagesDebug.set(c++, "dappResourceIdbytes ",abi.encodePacked(dappResourceIdbytes));
    // DappMessagesDebug.set(c++, "subs size ",abi.encodePacked(subscriptions.length));

    bytes memory returnData = IWorld(_world()).call(
      dappSystemResourceId,
      abi.encodeWithSignature("prepareInput(bytes)", _payload));

    ResourceId coreDappSystem = WorldResourceIdLib.encode(RESOURCE_SYSTEM, "core", "DappSystem");

    // // add msg sender bytes in between
    bytes memory _proxiedPayload = abi.encodePacked(_payload[:4],_msgSender(),_payload[4:]);

    // // DEBUG
    // uint32 c = DebugCounter.get();
    // address dapp;
    // DappMessagesDebug.set(c++, "", abi.encodePacked(coreDappSystem));
    // DappMessagesDebug.set(c++, "", inputBoxCalls[subscriptions.length].callData);
    // DebugCounter.set(c);

    returnData = IWorld(_world()).call(
      coreDappSystem,
      abi.encodeWithSignature("addInputToCartesiInputBox(bytes32,bytes)", dappSystemResourceId, _proxiedPayload));

    return bytes32(returnData);
  }

  function addInputToCartesiInputBox(bytes32 resourceId, bytes calldata _payload) public returns (bytes32) {
    address dapp = NamespaceDappAddress.get(resourceId);
    if (dapp == address(0)) revert DappSystem__InvalidResource();
    
    // debug to see event
    uint32 c = DebugCounter.get();
    DappMessagesDebug.set(c++, "addInputToCartesiInputBox", abi.encode(dapp,_payload));
    DebugCounter.set(c);

    // return 0x0;
    return IWorld(_world()).core__proxyAddInput(dapp, _payload);
  }


  function setNamespaceSystem(address _dapp, ResourceId systemResource) public {

    // uint32 c = DebugCounter.get();

    // DappMessagesDebug.set(c++, "tx.origin", abi.encode(tx.origin));
    // DappMessagesDebug.set(c++, "_msgSender()", abi.encode(_msgSender()));
    // DappMessagesDebug.set(c++, "Ownable(_dapp).owner()", abi.encode(Ownable(_dapp).owner()));
    // DappMessagesDebug.set(c++, "ICartesiDApp(_dapp).getTemplateHash()", abi.encode(ICartesiDApp(_dapp).getTemplateHash()));

    // check namespace owner
    // AccessControl.requireOwner(systemResource, tx.origin);
    if (NamespaceOwner.get(systemResource.getNamespaceId()) != tx.origin) revert DappSystem__InvalidOwner();

    // comment for nonodo
    // check dapp owner
    if (Ownable(_dapp).owner() != tx.origin) revert DappSystem__InvalidOwner();

    // check dapp is dapp (checking only get template hash)
    (bool success, bytes memory data) = _dapp.staticcall(abi.encodeWithSignature("getTemplateHash()"));
    if (!success || data.length != 32) revert DappSystem__InvalidDapp();
    // comment for nonodo /devnet
    if (ICartesiDApp(_dapp).getTemplateHash() != bytes32(0)) revert DappSystem__InvalidDapp();

    // DebugCounter.set(c);
    DappAddressNamespace.set(_dapp, bytes32(abi.encodePacked(systemResource)));
    NamespaceDappAddress.set(bytes32(abi.encodePacked(systemResource)),_dapp);
  }


}
