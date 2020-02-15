pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILoanPool {
    function lend(
        IERC20 token,
        uint256 amount,
        ILoanPoolLoaner loaner,
        bytes calldata data
    ) external;
}
