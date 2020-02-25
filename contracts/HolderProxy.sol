pragma solidity ^0.5.0;

import "./IHolder.sol";


contract HolderProxy is IIProxy {

    address private _delegate;
    address public owner = msg.sender;

    function delegate() public view returns(address) {
        return _delegate;
    }

    function upgradeDelegate(address newDelegate) public {
        require(msg.sender == owner, "Access denied");
        if (_delegate != newDelegate && newDelegate != address(0)) {
            _delegate = newDelegate;
        }
    }

    function() external payable {
        address _impl = _delegate;
        require(_impl != address(0), "Delegate not initialized");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
