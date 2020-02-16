pragma solidity ^0.5.0;


interface ICompoundController {
    function enterMarkets(address[] calldata cTokens) external returns(uint256[] memory);
    function checkMembership(address account, address cToken) external view returns (bool);
}
