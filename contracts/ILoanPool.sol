pragma solidity ^0.5.0;

interface ILoanPool {
    function lend(
        address token,
        uint256 amount,
        address loaner,
        bytes calldata data
    ) external;
}
