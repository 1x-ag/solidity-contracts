pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICompoundController.sol";

contract ICERC20 is IERC20 {
    function comptroller() external view returns(ICompoundController);
    function balanceOfUnderlying(address account) external view returns(uint256);
    function borrowBalanceStored(address account) external view returns(uint256);

    function mint() external payable;
    function mint(uint256 amount) external returns(uint256);
    function redeem(uint256 amount) external returns(uint256);
    function borrow(uint256 amount) external returns(uint256);
    function repayBorrow() external payable returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
}
