pragma solidity ^0.5.0;

interface IFlashLoanReceiver {
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}
