pragma solidity ^0.5.0;


contract HolderProxy {

    address public owner = msg.sender;
    address public delegate;

    function upgradeDelegate(address newDelegate) public {
        require(msg.sender == owner, "Access denied");
        if (delegate != newDelegate) {
            delegate = newDelegate;
        }
    }

    function() external payable {
        require(delegate != address(0), "Delegate not initialized");
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize)
            let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize)
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
        }
    }
}
