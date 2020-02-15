pragma solidity ^0.5.0;

contract LoanHolder {
    address public owner = msg.sender;
    address public sellTokenAddress;
    address public buyTokenAddress;

    constructor(address _sellTokenAddress, address _buyTokenAddress) public {
        sellTokenAddress = _sellTokenAddress;
        buyTokenAddress = _buyTokenAddress;
    }

    function () external payable {
    }

    function perform(address target, uint256 value, bytes calldata data) external payable returns(bytes memory) {
        require(msg.sender == owner, "Not authorized caller");
        (bool success, bytes memory ret) = target.call.value(value)(data);
        require(success, "External call failed");
        return ret;
    }
}
