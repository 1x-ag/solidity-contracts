pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/aave/IFlashLoanReceiver.sol";
import "./interface/aave/ILendingPool.sol";
import "./UniversalERC20.sol";


contract FlashLoanAave {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    ILendingPool public constant POOL = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    address public constant CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    function _flashLoan(IERC20 token, uint256 amount, bytes memory data) internal {
        POOL.flashLoan(
            address(this),
            token.isETH() ? 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE : address(token),
            amount,
            data
        );
    }

    function _repayFlashLoan(IERC20 token, uint256 amount) internal {
        token.universalTransfer(CORE, amount);
    }

    // Callback for Aave flashLoan
    function executeOperation(
        address /*reserve*/,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    )
        external
    {
        require(msg.sender == address(POOL), "Access denied, only pool alowed");
        (bool success, bytes memory data) = address(this).call(abi.encodePacked(params, amount.add(fee)));
        require(success, string(abi.encodePacked("External call failed: ", data)));
    }
}
