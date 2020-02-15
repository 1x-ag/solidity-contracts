pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./LoanHolder.sol";
import "./aave/IlendingPool.sol";
import "./compound/ICompoundController.sol";
import "./compound/ICERC20.sol";

contract OneXLeverageCompound is AaveFlashLoanReciever {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    ILendingPool private aavePool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    address private AAVE_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;
    mapping (address => address) private _loanHolderOwners;

    modifier onlyTokenOwner(address loanHolder) {
        require(_loanHolderOwners(loanHolder) == msg.sender, "msg.sender should be owner of token holder");

        _;
    }

    modifier checkLeverage(uint256 leverageRatio) {
        require(leverageRatio > 1, "leverage ratio is too small");
        require(leverageRatio < 10, "leverage ratio is too small");

        _;
    }

    function() external payable {
        require(msg.sender != tx.origin, "Not allowed");
    }

    function openPosition(
        address sellTokenAddress,
        uint256 sellTokenAmount,
        address buyTokenAddress,
        uint256 leverageRatio
    )
        external
        payable
        checkLeverage(leverageRatio)
    {
        IERC20 sellToken = IERC20(sellTokenAddress);
        // transfer sellToken from user
        sellToken.universalTransferFrom(msg.sender, address(this), sellTokenAmount);

        aavePool.flashLoan(
            address(this),
            sellTokenAddress,
            sellTokenAmount.mul(leverageRatio - 1),
            abi.encodeWithSelector(
                this.openPositionCallback.selector,
                sellTokenAddress,
                sellTokenAmount,
                buyTokenAddress,
                leverageRatio
            )
        );
    }

    function openPositionCallback(
        address sellTokenAddress,
        uint256 sellTokenAmount,
        address buyTokenAddress,
        uint256 leverageRatio,
        uint256 sellTokenRepayAmount
    )
        external
    {
        LoanHolder holder = _initNewHolder(sellTokenAddress, buyTokenAddress);
        // exchange sellToken to buyToken
        uint256 buyTokenAmount = _exchange(sellTokenAddress, sellTokenAmount.mul(leverageRatio), buyTokenAddress);
        // use buyToken as collateral to open position
        _mint(holder, buyTokenAddress, buyTokenAmount);
        // borrow sellToken
        _borrow(holder, sellTokenAddress, sellTokenRepayAmount);
        // repay flash loan with sellToken
        _repayFlashLoan(sellTokenAddress, sellTokenRepayAmount);
    }

    function closePosition(LoanHolder holder) external onlyTokenOwner(holder)
    {
        uint256 amount = ICERC20(_getCTokenbyToken(holder.sellTokenAddress)).borrowBalanceCurrent(address(holder));

        aavePool.flashLoan(
            address(this),
            holder.sellTokenAddress,
            sellTokenAmount.mul(leverageRatio - 1),
            abi.encodeWithSelector(
                this.closePositionCallback.selector,
                holder,
                amount
            )
        );

    }

    function closePositionCallback(
        LoanHolder holder,
        uint256 sellTokenAmount,
        uint256 sellTokenRepayAmount
    )
        external
    {
        address sellTokenAddress = holder.sellTokenAddress;
        address buyTokenAddress = holder.buyTokenAddress;
        // use sellToken to close position
        _repay(holder, sellTokenAddress, sellTokenAmount);
        // withdraw buyToken collateral
        _redeemAll(holder, buyTokenAddress);
        // exchange buyToken to sellToken
        uint256 totalSellTokenAmount = _exchange(
            buyTokenAddress,
            IERC20(buyTokenAddress).universalBalanceOf(address(this)),
            sellTokenAddress
        );
        require(totalSellTokenAmount > sellTokenRepayAmount, "not enough tokens to repay flash loan");
        // repay flash loan with sellToken
        _repayFlashLoan(sellTokenAddress, sellTokenAmountToReturn);
        // send remainder to owner
        IERC20(sellTokenAddress).universalTransfer(_loanHolderOwners(loanHolder), totalSellTokenAmount - sellTokenAmountToReturn);
    }

    function _exchange(address fromToken, uint256 amount, address toToken) private returns(uint256) {
        // TODO
        return 0;
    }

    function _repayFlashLoan(address tokenAddress, uint256 amount) private {
        IERC20 token = IERC20(tokenAddress);
        token.universalTransfer(AAVE_CORE, amount);
    }

    function _borrow(address holder, address tokenAddress, uint256 amount) private {
        ICERC20 cToken = ICERC20(_getCTokenbyToken(tokenAddress));
        IERC20 token = IERC20(tokenAddress);
        holder.perform(address(cToken), 0, abi.encodeWithSelector(
            cToken.borrow.selector,
            amount
        ));
        if (tokenAddress != address(0)) {
            holder.perform(tokenAddress, 0, abi.encodeWithSelector(
                token.transfer.selector,
                address(this),
                token.universalBalanceOf(address(holder))
            ));
        } else {
            holder.perform(address(this), token.universalBalanceOf(address(holder)), "");
        }
    }

    function _repay(address holder, address tokenAddress, uint256 amount) private {
        ICERC20 cToken = ICERC20(_getCTokenbyToken(tokenAddress));
        IERC20 token = IERC20(tokenAddress);
        token.universalApprove(address(cToken), amount);
        if (tokenAddress != address(0)) {
            cToken.repayBorrowBehalf(holder, amount);
        } else {
            (bool success,) = address(cToken).call.value(amount)(
                abi.encodeWithSignature(
                    "repayBorrowBehalf(address)",
                    holder
                )
            );
            require(success, "repay failed");
        }
    }

    function _redeemAll(address holder, address tokenAddress) private {
        IERC20 token = IERC20(_getCTokenbyToken(tokenAddress));
        _redeem(holder, tokenAddress, token.universalBalanceOf(holder));
    }

    function _redeem(address holder, address tokenAddress, uint256 amount) private {
        ICERC20 cToken = ICERC20(_getCTokenbyToken(tokenAddress));
        IERC20 token = IERC20(tokenAddress);

        holder.perform(address(cToken), 0, abi.encodeWithSelector(
            cToken.redeem.selector,
            amount
        ));

        if (tokenAddress != address(0)) {
            holder.perform(tokenAddress, 0, abi.encodeWithSelector(
                token.transfer.selector,
                address(this),
                token.universalBalanceOf(address(holder))
            ));
        } else {
            holder.perform(address(this), token.universalBalanceOf(address(holder)), "");
        }

    }

    function _mint(address holder, address tokenAddress, uint256 amount) private {
        ICERC20 cToken = ICERC20(_getCTokenbyToken(tokenAddress));
        IERC20 token = IERC20(tokenAddress);
        token.universalApprove(address(cToken), amount);
        if (tokenAddress == 0) {
            cToken.mint(amount);
        } else {
            (bool success,) = address(cToken).call.value(amount)(
                abi.encodeWithSignature("mint()")
            );
            require(success, "mint failed");
        }
        cToken.universalTransfer(
            holder,
            cToken.universalBalanceOf(address(this))
        );
    }

    function _initNewHolder(address sellTokenAddress, address buyTokenAddress) private returns(LoanHolder) {
        LoanHolder holder = new LoanHolder(sellTokenAddress, buyTokenAddress);
        _enterMarket(
            holder,
            ICERC20(_getCTokenbyToken(buyTokenAddress)).comptroller(),
            _getCTokenbyToken(buyTokenAddress),
            _getCTokenbyToken(sellTokenAddress)
        );
        return holder;
    }

    function _enterMarket(
        LoanHolder holder,
        ICompoundController controller,
        address cToken1,
        address cToken2
    )
        internal
        returns(LoanHolder)
    {
        holder.perform(address(controller), 0, abi.encodeWithSelector(
            controller.enterMarkets.selector,
            uint256(0x20), // offset
            uint256(2),    // length
            cToken1,
            cToken2
        ));
    }

    function _getCTokenbyToken(address token) private pure returns(address)
    {
        if (token == 0x6B175474E89094C44Da98b954EedeAC495271d0F) {  // DAI
            return 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;  // cDAI
        } else if (token == 0) { // ETH
            return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;  // cETH
        } else {
            require(false, "Unsupported token");
        }
    }

    // callback for Aave flashLoan
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
    {
        (bool success,) = address(this).call(abi.encodePacked(_params, _amount.add(_fee)));
        require(success, "External call failed");
    }
}
