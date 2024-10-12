// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CurrencyToken is ERC20 {
    constructor() ERC20("CurrencyToken", "CT") {
        _mint(msg.sender, 1000000000);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
