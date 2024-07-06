// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICartridgeModel.sol";

contract CartridgeModelVanguard3v2 is ICartridgeModel,Ownable {
    error Cartridge__ErrorCode();
    error Cartridge__CartridgeOwnerNotDefined();

    constructor() Ownable(tx.origin) {}

    // cartridgeOwner
    mapping (bytes32 => address) public cartridgeOwners;

    // admin
    function setCartridgeOwner(bytes32 cartridgeId, address cartridgeOwnerAddress) external onlyOwner {
        cartridgeOwners[cartridgeId] = cartridgeOwnerAddress;
    }

    // Decode and validate tape from cartridge
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

    function decodeCartridgeUser(bytes calldata data) override view external returns (bytes32,address) {
        if (data.length == 0) return (bytes32(0),address(0));
        (, bytes32 cartridgeId, , , , , , , , , uint errorCode) = abi.decode(data,
            (bytes32, bytes32, int, address, uint, int, string, int, bytes32, int, uint)
        );
        
        if (errorCode != 0) revert Cartridge__ErrorCode();
        if (cartridgeOwners[cartridgeId] == address(0)) revert Cartridge__CartridgeOwnerNotDefined();

        return (cartridgeId,cartridgeOwners[cartridgeId]);
    }

    function decodeCartridgeMetadata(bytes calldata) override pure external 
        returns (bytes32, uint, bytes32, int) 
    {
        return (bytes32(0),0,bytes32(0),0);
    }

}
