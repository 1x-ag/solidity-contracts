pragma solidity ^0.5.0;

interface ILendingPool {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
    function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
    function repay(address _reserve, uint256 _amount, address payable _onBehalfOf) external payable;
    function flashLoan(address _receiver, address _reserve, uint256 _amount, bytes calldata _params) external;
}
