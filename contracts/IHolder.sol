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

    function collateralAmount(IERC20 token) public returns(uint256);
    function borrowAmount(IERC20 token) public returns(uint256);
}
