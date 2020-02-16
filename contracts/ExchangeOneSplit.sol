pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IOneSplit.sol";
import "./UniversalERC20.sol";
import "./IHolder.sol";


contract ExchangeOneSplit is IHolder {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IOneSplit public oneSplit = IOneSplit(0xDFf2AA5689FCBc7F479d8c84aC857563798436DD);

    function _exchange(IERC20 fromToken, IERC20 toToken, uint256 amount) internal returns(uint256) {
        fromToken.universalApprove(address(oneSplit), amount);

        uint256 beforeBalance = toToken.balanceOf(address(this));
        oneSplit.goodSwap(
            fromToken,
            toToken,
            amount,
            0,
            5,
            0
        );

        return toToken.balanceOf(address(this)).sub(beforeBalance);
    }
}