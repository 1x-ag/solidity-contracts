pragma solidity ^0.5.0;

interface ICompoundController {
    function enterMarkets(address[] calldata cTokens) external returns(uint[] memory);
}
