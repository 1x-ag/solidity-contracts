pragma solidity ^0.5.0;


interface IToken {
    function assetBalanceOf(address _owner) external view returns (uint256);
}
