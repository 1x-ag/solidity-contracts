pragma solidity ^0.5.0;

import "./IPriceOracle.sol";


interface ICompoundController {
    function oracle() external view returns(IPriceOracle);
    function enterMarkets(address[] calldata cTokens) external returns(uint256[] memory);
    function checkMembership(address account, address cToken) external view returns (bool);
}
