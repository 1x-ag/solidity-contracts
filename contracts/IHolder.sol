pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IHolder {
    function openPosition(
        IERC20 collateral,
        IERC20 debt,
        uint256 amount,
        uint256 leverageRatio
    )
        external
        payable
        returns(uint256);

    function closePosition(
        IERC20 collateral,
        IERC20 debt,
        address user
    )
        external;

    function collateralAmount(IERC20 token) public view returns(uint256);
    function borrowAmount(IERC20 token) public view returns(uint256);

    // Internal API

    function _flashLoan(IERC20 asset, uint256 amount, bytes memory data) internal;
    function _repayFlashLoan(IERC20 token, uint256 amount) internal;

    function _exchange(IERC20 fromToken, IERC20 toToken, uint256 amount) internal returns(uint256);

    function _deposit(IERC20 token, uint256 amount) internal;
    function _redeem(IERC20 token, uint256 amount) internal;
    function _redeemAll(IERC20 token) internal;
    function _borrow(IERC20 token, uint256 amount) internal;
    function _repay(IERC20 token, uint256 amount) internal;
}
