// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICartridgeModel.sol";

contract CartridgeModelVanguard3 is ICartridgeModel {

    // Vanguard4 up
    // struct EventModel {
    //     bytes32 version;
    //     bytes32 cartridgeId;
    //     int cartridgeInputIndex;
    //     address user;
    //     uint timestamp;
    // }

    // Vanguard3 3.5
    // struct EventModel {
    //     string cartridgeId;
    //     string user;
    //     uint timestamp;
    // }
    
    // function decodeCartridgeUser(bytes calldata data) override pure external returns (bytes32,address) {
    //     if (data.length == 0) return (bytes32(0),address(0));
    //     EventModel memory payload;
    //     (payload.cartridgeId, payload.user, payload.timestamp)
    //         = abi.decode(data,(string,string, uint));

    //     bytes32 cartridgeId = abi.decode(abi.encodePacked(fromHex(payload.cartridgeId)),(bytes32));

    //     address user = abi.decode(abi.encodePacked(fromHex(payload.user)),(address));

    //     return (cartridgeId, user);
    // }

    // function decodeCartridgeMetadata(bytes calldata data) override pure external 
    //     returns (bytes32, bytes32, int) 
    // {
    //     if (data.length == 0) return (bytes32(0),bytes32(0),0);
        
    //     EventModel memory payload;
    //     (payload.cartridgeId, payload.user, payload.timestamp)
    //         = abi.decode(data,(string,string, uint));

    //     bytes32 cartridgeId = abi.decode(abi.encodePacked(fromHex(payload.cartridgeId)),(bytes32));

    //     return (bytes32(0), cartridgeId, 0);
    // }

    // function fromHexChar(uint8 c) public pure returns (uint8) {
    //     if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
    //         return c - uint8(bytes1('0'));
    //     }
    //     if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
    //         return 10 + c - uint8(bytes1('a'));
    //     }
    //     if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
    //         return 10 + c - uint8(bytes1('A'));
    //     }
    //     revert("fail");
    // }

    // function fromHex(string memory s) public pure returns (bytes memory) {
    //     bytes memory ss = bytes(s);
    //     require(ss.length%2 == 0); // length must be even
    //     bytes memory r = new bytes(ss.length/2);
    //     for (uint i=0; i<ss.length/2; ++i) {
    //         r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
    //                     fromHexChar(uint8(ss[2*i+1])));
    //     }
    //     return r;
    // }

    function decodeCartridgeUser(bytes calldata) override pure external returns (bytes32,address) {
        return (bytes32(0),address(0));
    }

    function decodeCartridgeMetadata(bytes calldata) override pure external 
        returns (bytes32, bytes32, int) 
    {
        return (bytes32(0),bytes32(0),0);
    }

}
