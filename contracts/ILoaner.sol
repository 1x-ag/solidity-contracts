pragma solidity ^0.5.0;

import "./ILoanPool.sol";

contract ILoaner {

    modifier withLoan(
        ILoanPool pool,
        address token,
        uint256 amount
    ) {
        if (msg.sender != address(this)) {
            pool.lend(
                token,
                amount,
                address(this),
                msg.data
            );
            return;
        }

        _;
    }

    function _getExpectedReturn() internal pure returns(uint256 amount) {
        assembly {
            amount := calldataload(sub(calldatasize, 32))
        }
    }

    function inLoan(
        uint256 expectedReturn,
        bytes calldata data
    )
        external
    {
        (bool success,) = address(this).call(abi.encodePacked(data, expectedReturn));
        require(success, "External call failed");
    }
}
