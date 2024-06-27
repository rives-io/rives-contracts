// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITapeModel.sol";

contract TapeModelVanguard3 is  ITapeModel {
    function getRoyaltiesTapes(bytes calldata) override pure external returns (bytes32[] memory) {
        return new bytes32[](0);
    }

    struct TapePayloadModel {
        bytes32 version;
        bytes32 cartridgeId;
        int cartridgeInputIndex;
        address user;
        uint timestamp;
        int score;
        string ruleId;
        int ruleInputIndex;
        bytes32 tapeId;
        int tapeInputIndex;
        uint errorCode;
    }

    // process notice
    // version:                Bytes32
    // cartridge_id:           Bytes32
    // cartridge_input_index:  Int
    // user_address:           Address
    // timestamp:              UInt
    // score:                  Int
    // rule_id:                String
    // rule_input_index:       Int
    // tape_hash:              Bytes32
    // tape_input_index:       Int
    // error_code:             UInt

    function decodeTapeUsers(bytes calldata data) override pure external returns (bytes32,address,address) {
        if (data.length == 0) return (bytes32(0),address(0),address(0));
        (, , , address tapeCreator, , , , , bytes32 tapeId, , uint errorCode) = abi.decode(data,
            (bytes32, bytes32, int, address, uint, int, string, int, bytes32, int, uint)
        );
        
        if (errorCode != 0) revert Tape__ErrorCode();

        return (tapeId, address(0), tapeCreator);
    }

    function decodeTapeMetadata(bytes calldata data) override pure external 
        returns (bytes32, bytes32, int, bytes32, int, bytes32, int) 
    {
        if (data.length == 0) return (bytes32(0),bytes32(0),0,bytes32(0),0,bytes32(0),0);
        
        TapePayloadModel memory payload;
        (payload.version, payload.cartridgeId, payload.cartridgeInputIndex, , , , payload.ruleId, payload.ruleInputIndex, payload.tapeId, payload.tapeInputIndex, payload.errorCode)
            = abi.decode(data,
                (bytes32, bytes32, int, address, uint, int, string, int, bytes32, int, uint)
        );

        if (payload.errorCode != 0) revert Tape__ErrorCode();

        bytes32 ruleId = abi.decode(abi.encodePacked(fromHex(payload.ruleId)),(bytes32));

        return (payload.version, payload.cartridgeId, payload.cartridgeInputIndex, ruleId, payload.ruleInputIndex, 
            payload.tapeId, payload.tapeInputIndex );
    }

    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
        revert("fail");
    }

    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }
}