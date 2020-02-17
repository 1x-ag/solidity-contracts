pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IHolder.sol";
import "./lib/UniversalERC20.sol";


contract HolderBase is IHolder {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    address public delegate;
    address public owner = msg.sender;
    uint256 private _stopLoss;
    uint256 private _takeProfit;

    modifier onlyOwner {
        require(msg.sender == owner, "Access denied");
        _;
    }

    modifier onlyCallback {
        require(msg.sender == address(this), "Access denied");
        _;
    }

    function stopLoss() public view returns(uint256) {
        return _stopLoss;
    }

    function takeProfit() public view returns(uint256) {
        return _takeProfit;
    }

    function() external payable {
        require(msg.sender != tx.origin);
    }

    function pnl(IERC20 collateral, IERC20 debt, uint256 leverageRatio) public returns(uint256) {
        uint256 value = _pnl(collateral, debt);
        if (value > 1e18) {
            return uint256(1e18).add(
                value.sub(1e18).mul(leverageRatio)
            );
        } else {
            return uint256(1e18).sub(
                uint256(1e18).sub(value).mul(leverageRatio)
            );
        }
    }

    function openPosition(
        IERC20 collateral,
        IERC20 debt,
        uint256 amount,
        uint256 leverageRatio,
        uint256 stopLossValue,
        uint256 takeProfitValue
    )
        external
        payable
        onlyOwner
        returns(uint256)
    {
        _stopLoss = stopLossValue;
        _takeProfit = takeProfitValue;

        debt.universalTransferFrom(msg.sender, address(this), amount);

        _flashLoan(
            debt,
            amount.mul(leverageRatio.sub(1)),
            abi.encodeWithSelector(
                this.openPositionCallback.selector,
                collateral,
                debt,
                amount,
                leverageRatio
                // repayAmount added dynamically in executeOperation
            )
        );

        return collateralAmount(collateral);
    }

    function openPositionCallback(
        IERC20 collateral,
        IERC20 debt,
        uint256 amount,
        uint256 leverageRatio,
        uint256 repayAmount
    )
        external
        onlyCallback
    {
        uint256 value = _exchange(debt, collateral, amount.mul(leverageRatio));
        _deposit(collateral, value);
        _borrow(debt, repayAmount);
        _repayFlashLoan(debt, repayAmount);
    }

    function closePosition(
        IERC20 collateral,
        IERC20 debt,
        address user
    )
        external
        onlyOwner
    {
        uint256 borrowedAmount = borrowAmount(debt);

        _flashLoan(
            debt,
            borrowedAmount,
            abi.encodeWithSelector(
                this.closePositionCallback.selector,
                collateral,
                debt,
                user,
                borrowedAmount
                // repayAmount added dynamically in executeOperation
            )
        );
    }

    function closePositionCallback(
        IERC20 collateral,
        IERC20 debt,
        address user,
        uint256 borrowedAmount,
        uint256 repayAmount
    )
        external
        onlyCallback
    {
        _repay(debt, borrowedAmount);
        _redeemAll(collateral);
        uint256 returnedAmount = _exchange(collateral, debt, collateral.universalBalanceOf(address(this)));
        _repayFlashLoan(debt, repayAmount);
        debt.universalTransfer(user, returnedAmount.sub(repayAmount));
    }

    // Internals for overriding

    function _flashLoan(IERC20 asset, uint256 amount, bytes memory data) internal;
    function _repayFlashLoan(IERC20 token, uint256 amount) internal;

    function _exchange(IERC20 fromToken, IERC20 toToken, uint256 amount) internal returns(uint256);

    function _pnl(IERC20 collateral, IERC20 debt) internal returns(uint256);
    function _deposit(IERC20 token, uint256 amount) internal;
    function _redeem(IERC20 token, uint256 amount) internal;
    function _redeemAll(IERC20 token) internal;
    function _borrow(IERC20 token, uint256 amount) internal;
    function _repay(IERC20 token, uint256 amount) internal;
}
