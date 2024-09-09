// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { ITapeSubmission } from "../interfaces/ITapeSubmission.sol";

interface RivesAsset {
  function setTapeParams(bytes32) external;
}

interface WorldWithFuncs {
  function getCartridgeOwner(bytes32) view external returns (address);
}

contract FeeTapeSubmission is ITapeSubmission, Ownable {

  uint256 private constant MIN_BOOL_LENGTH = 31; // uint8 = 32 bytes
  uint256 private constant MIN_UINT8_LENGTH = 31; // uint8 = 32 bytes
  uint256 private constant MIN_STRING_LENGTH = 95; // empty string = 64 bytes, 1 character = 96 bytes

  address public worldAddress;

  constructor(address ownerAddress) Ownable(ownerAddress) {}

  function setWorldAddress(address addr) external onlyOwner {
    worldAddress = addr;
  }
  
  receive() external payable {}

  function getTapeIdFromRuleAndHash(bytes calldata ruleId,bytes calldata payloadHash) public pure returns (bytes32) {
    return bytes32(abi.encodePacked(ruleId[:20],payloadHash[:12]));
  }

  function _checkMethodExists(address implementation, bytes memory methodBytes, uint256 minLength) internal view returns (bool) {
      (bool success, bytes memory data) = implementation.staticcall(methodBytes);
      return success && data.length > minLength;
  }

  function validateConfig(bytes32,bytes calldata config) external view returns (bool) {

    (address token, ) = abi.decode(config,(address,uint256));

    if (token != address(0)) {
        // validate token 
        if(!_checkMethodExists(token, abi.encodeWithSignature("decimals()"), MIN_UINT8_LENGTH)) 
            revert TapeSubmission__InvalidConfig('decimals');
        if(!_checkMethodExists(token, abi.encodeWithSignature("name()"), MIN_STRING_LENGTH)) 
            revert TapeSubmission__InvalidConfig('name');
        if(!_checkMethodExists(token, abi.encodeWithSignature("symbol()"), MIN_STRING_LENGTH)) 
            revert TapeSubmission__InvalidConfig('symbol');
        // if (fee > 1000000000000000000)
        //     revert FeeTapeSubmission__InvalidConfig("value");
    } else {
        // if (fee > 1000000000000000000)
        //     revert FeeTapeSubmission__InvalidConfig("value");
    }
    
    return true;
  }

  function validateTapeSubmission(
      address sender,uint256 value, bytes32 cartridgeId, bytes calldata payload, bytes calldata config) 
      external returns (bytes32) {
    
    address cartridgeOwner = WorldWithFuncs(worldAddress).getCartridgeOwner(cartridgeId);

    (address token, uint256 fee) = abi.decode(config,(address,uint256));

    if (token != address(0)) {
        if (!ERC20(token).transferFrom(sender, cartridgeOwner, fee))
            revert TapeSubmission__CannotSubmit("Couldn't transfer");
    } else {
        if (address(this).balance < value) revert TapeSubmission__CannotSubmit("Invalid value");
        if (address(this).balance < fee) revert TapeSubmission__CannotSubmit("Insufficient value");
        (bool sent, ) = payable(cartridgeOwner).call{value: fee}("");
        if (!sent) revert TapeSubmission__CannotSubmit("Couldn't transfer");
        (sent, ) = payable(sender).call{value: value - fee}("");
        if (!sent) revert TapeSubmission__CannotSubmit("Couldn't give change");
    }
    
    (,,bytes memory tape,,,) = abi.decode(payload[4:],(bytes32,bytes32,bytes,int,bytes32[],bytes));

    bytes32 payloadHash = keccak256(tape);
    bytes32 tapeId = this.getTapeIdFromRuleAndHash(abi.encodePacked(payload[4:36]), abi.encodePacked(payloadHash));

    return tapeId;
  }

  function prepareTapeSubmission(
      bytes32, bytes calldata) 
      external pure returns (bool) {
    return true;
  }

}
