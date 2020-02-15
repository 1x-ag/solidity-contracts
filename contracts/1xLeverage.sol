pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ILoaner.sol";

contract OneXLeverage is ILoaner {
    using SafeMath for uint256;

    function openPosition(
        address sellTokenAddress,
        uint256 sellTokenAmount,
        address buyTokenAddress,
        uint256 leverageRatio
    )
        external
        withLoan(
            0xDEADBEEF,  // Hardcode pool
            sellTokenAddress,
            sellTokenAmount.mul(leverageRatio.sub(1))
        )
    {
        // exchange sellToken to buyToken
        // use buyToken as collateral to open position
        // borrow sellToken
        // repay flash loan with sellToken
    }


    function closePosition(
        uint256 positionId
        // add all the info about the position
    )
        external
        withLoan(
            0xDEADBEEF,  // Hardcode pool
            sellTokenAddress, // ??
            sellTokenAmount // ??
        )
    {
        // use sellToken to close position
        // exchange buyToken to sellToken
        // repay flash loan with sellToken
        // send remainder to msg.sender
    }

}
