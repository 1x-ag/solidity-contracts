pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IHolder.sol";
import "./UniversalERC20.sol";


contract HolderBase is IHolder {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    address public owner = msg.sender;
    address public delegate;

    modifier onlyOwner {
        require(msg.sender == owner, "Access denied");
        _;
    }

    modifier onlyCallback {
        require(msg.sender == address(this), "Access denied");
        _;
    }

    function openPosition(
        IERC20 collateral,
        IERC20 debt,
        uint256 amount,
        uint256 leverageRatio
    )
        external
        payable
        onlyOwner
        returns(uint256)
    {
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
}
