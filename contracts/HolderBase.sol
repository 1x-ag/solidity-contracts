pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IHolder.sol";
import "./lib/UniversalERC20.sol";


contract HolderBase is IHolder {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    address private _delegate;
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

    function delegate() public view returns(address) {
        return _delegate;
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
        return _pnl(collateral, debt).mul(leverageRatio.sub(1)).div(leverageRatio);
    }

    function openPosition(
        IERC20 collateral,
        IERC20 debt,
        uint256 leverageRatio,
        uint256 amount,
        uint256 minReturn,
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
                leverageRatio,
                amount,
                minReturn
                // repayAmount added dynamically in executeOperation
            )
        );

        return collateralAmount(collateral);
    }

    function openPositionCallback(
        IERC20 collateral,
        IERC20 debt,
        uint256 leverageRatio,
        uint256 amount,
        uint256 minReturn,
        uint256 repayAmount
    )
        external
        onlyCallback
    {
        uint256 value = _exchange(debt, collateral, amount.mul(leverageRatio), minReturn);
        _deposit(collateral, value);
        _borrow(debt, repayAmount);
        _repayFlashLoan(debt, repayAmount);
    }

    function closePosition(
        IERC20 collateral,
        IERC20 debt,
        address user,
        uint256 minReturn
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
                minReturn,
                borrowedAmount
                // repayAmount added dynamically in executeOperation
            )
        );
    }

    function closePositionCallback(
        IERC20 collateral,
        IERC20 debt,
        address user,
        uint256 minReturn,
        uint256 borrowedAmount,
        uint256 repayAmount
    )
        external
        onlyCallback
    {
        _repay(debt, borrowedAmount);
        _redeemAll(collateral);
        uint256 returnedAmount = _exchange(collateral, debt, collateral.universalBalanceOf(address(this)), minReturn);
        _repayFlashLoan(debt, repayAmount);
        debt.universalTransfer(user, returnedAmount.sub(repayAmount));
    }
}
