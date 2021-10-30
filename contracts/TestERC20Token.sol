// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20Token is ERC20{

    constructor() ERC20("Artifact ERC20","AT"){
        super._min(msg.sender,100000000000000 * (10**18));
    }
}