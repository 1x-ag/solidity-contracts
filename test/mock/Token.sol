pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Token is ERC20 {
    constructor(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
