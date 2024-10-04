// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@interfaces/ICartridgeModel.sol";

contract CartridgeModel is ICartridgeModel {
    // Vanguard4 up
    struct EventModel {
        bytes32 version;
        bytes32 cartridgeId;
        int256 cartridgeInputIndex;
        address user;
        uint256 timestamp;
    }

    function decodeCartridgeUser(bytes calldata data) external pure override returns (bytes32, address) {
        if (data.length == 0) return (bytes32(0), address(0));
        EventModel memory payload;
        (, payload.cartridgeId,, payload.user,) = abi.decode(data, (bytes32, bytes32, int256, address, uint256));

        return (payload.cartridgeId, payload.user);
    }

    function decodeCartridgeMetadata(bytes calldata data)
        external
        pure
        override
        returns (bytes32, uint256, bytes32, int256)
    {
        if (data.length == 0) return (bytes32(0), 0, bytes32(0), 0);

        EventModel memory payload;
        (payload.version, payload.cartridgeId, payload.cartridgeInputIndex,, payload.timestamp) =
            abi.decode(data, (bytes32, bytes32, int256, address, uint256));

        return (payload.version, payload.timestamp, payload.cartridgeId, payload.cartridgeInputIndex);
    }
}
