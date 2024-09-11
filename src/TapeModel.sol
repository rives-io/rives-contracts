// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ITapeModel.sol";

contract TapeModel is ITapeModel {

    // VerificationOutput
    // version:                Bytes32
    // cartridge_id:           Bytes32
    // cartridge_input_index:  Int
    // cartridge_user_address: Address
    // user_address:           Address
    // timestamp:              UInt
    // score:                  Int
    // rule_id:                Bytes32
    // rule_input_index:       Int
    // tape_id:                Bytes32
    // tape_input_index:       Int
    // error_code:             UInt
    // tapes:                  Bytes32List

    struct TapePayloadModel {
        bytes32 version;
        bytes32 cartridgeId;
        int cartridgeInputIndex;
        address cartridgeUserAddress;
        address userAddress;
        uint timestamp;
        int score;
        bytes32 ruleId;
        int ruleInputIndex;
        bytes32 tapeId;
        int tapeInputIndex;
        uint errorCode;
        bytes32[] tapes;
    }

    function decodeTapeUsers(bytes calldata data) override pure external 
            returns (bytes32,address,address) {
        if (data.length == 0) return (bytes32(0),address(0),address(0));
        (, , , address cartridgeOwner, address tapeCreator, , , , , bytes32 tapeId, , uint errorCode,) = abi.decode(data,
            (bytes32, bytes32, int, address, address, uint, int, 
                bytes32, int, bytes32, int, uint, bytes32[])
        );
        
        if (errorCode != 0) revert Tape__ErrorCode();

        return (tapeId, cartridgeOwner, tapeCreator);
        // return (bytes32(0),address(0),address(0));
    }

    function decodeTapeMetadata(bytes calldata data) override pure external 
            returns (bytes32, uint, int, bytes32, int, bytes32, int, bytes32, int) {
        if (data.length == 0) return (bytes32(0),0,0,bytes32(0),0,bytes32(0),0,bytes32(0),0);
        
        TapePayloadModel memory payload;

        (payload.version, payload.cartridgeId, payload.cartridgeInputIndex, , , payload.timestamp, 
                payload.score, , , , , , )
            = abi.decode(data,
                (bytes32, bytes32, int, address, address, uint, int, 
                bytes32, int, bytes32, int, uint, bytes32[])
        );

        (, , , , , , , 
                payload.ruleId, payload.ruleInputIndex, payload.tapeId, 
                payload.tapeInputIndex, payload.errorCode,)
            = abi.decode(data,
                (bytes32, bytes32, int, address, address, uint, int, 
                bytes32, int, bytes32, int, uint, bytes32[])
        );

        if (payload.errorCode != 0) revert Tape__ErrorCode();

        // return (bytes32(0),0,0,bytes32(0),0,bytes32(0),0,bytes32(0),0);
        return (payload.version, payload.timestamp, payload.score, payload.cartridgeId, payload.cartridgeInputIndex, 
            payload.ruleId, payload.ruleInputIndex, payload.tapeId, payload.tapeInputIndex );
    }

    function getRoyaltiesTapes(bytes calldata data) override pure external returns (bytes32[] memory) {
        if (data.length == 0) return new bytes32[](0);
        (, , , , , , , , , , , uint errorCode, bytes32[] memory tapes) = abi.decode(data,
            (bytes32, bytes32, int, address, address, uint, int, 
                bytes32, int, bytes32, int, uint, bytes32[])
        );
        
        if (errorCode != 0) revert Tape__ErrorCode();

        return tapes;
        // return new bytes32[](0);
    }

}
