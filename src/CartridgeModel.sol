// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICartridgeModel.sol";

contract CartridgeModel is ICartridgeModel {

    // Vanguard4 up
    struct EventModel {
        bytes32 version;
        bytes32 cartridgeId;
        int cartridgeInputIndex;
        address user;
        uint timestamp;
    }

    function decodeCartridgeUser(bytes calldata data) override pure external 
            returns (bytes32,address) {
        if (data.length == 0) return (bytes32(0),address(0));
        EventModel memory payload;
        (, payload.cartridgeId, , payload.user, )
            = abi.decode(data,(bytes32, bytes32, int, address, uint));

        return (payload.cartridgeId, payload.user);
    }

    function decodeCartridgeMetadata(bytes calldata data) override pure external 
            returns (bytes32, uint, bytes32, int) {
        if (data.length == 0) return (bytes32(0),0,bytes32(0),0);
        
        EventModel memory payload;
        (payload.version, payload.cartridgeId, payload.cartridgeInputIndex, , payload.timestamp)
            = abi.decode(data,(bytes32, bytes32, int, address, uint));

        return (payload.version, payload.timestamp, payload.cartridgeId, payload.cartridgeInputIndex);
    }
}
