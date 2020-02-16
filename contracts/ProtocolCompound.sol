pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/compound/ICERC20.sol";
import "./interface/compound/ICompoundController.sol";
import "./UniversalERC20.sol";


contract ProtocolCompound {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    function collateralAmount(IERC20 token) public returns(uint256) {
        return _getCToken(token).balanceOfUnderlying(address(this));
    }

    function borrowAmount(IERC20 token) public returns(uint256) {
        return _getCToken(token).borrowBalanceCurrent(address(this));
    }

    function _pnl(IERC20 collateral, IERC20 debt) internal returns(uint256) {
        ICERC20 cCollateral = _getCToken(collateral);
        ICERC20 cDebt = _getCToken(debt);
        IPriceOracle oracle = cCollateral.comptroller().oracle();
        return oracle.getUnderlyingPrice(address(cCollateral)).mul(collateralAmount(collateral))
            .mul(1e18)
            .div(
                oracle.getUnderlyingPrice(address(cDebt)).mul(borrowAmount(debt))
            );
    }

    function _deposit(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        if (!cToken.comptroller().checkMembership(address(this), address(cToken))) {
            _enterMarket(cToken);
        }

        if (token.isETH()) {
            // cToken.mint.value(amount)();
            // TypeError: Member "mint" not unique after argument-dependent lookup in contract ICERC20.
            (bool success,) = address(cToken).call.value(amount)(abi.encodeWithSignature("mint()"));
            require(success);
        } else {
            token.universalApprove(address(cToken), amount);
            cToken.mint(amount);
        }
    }

    function _redeem(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        cToken.redeem(amount);
    }

    function _redeemAll(IERC20 token) internal {
        ICERC20 cToken = _getCToken(token);
        _redeem(token, IERC20(cToken).universalBalanceOf(address(this)));
    }

    function _borrow(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        if (!cToken.comptroller().checkMembership(address(this), address(cToken))) {
            _enterMarket(cToken);
        }

        cToken.borrow(amount);
    }

    function _repay(IERC20 token, uint256 amount) internal {
        ICERC20 cToken = _getCToken(token);
        if (token.isETH()) {
            // cToken.repayBorrow.value(amount)();
            // TypeError: Member "repayBorrow" not unique after argument-dependent lookup in contract ICERC20.
            (bool success,) = address(cToken).call.value(amount)(abi.encodeWithSignature("repayBorrow()"));
            require(success);
        } else {
            token.universalApprove(address(cToken), amount);
            cToken.repayBorrow(amount);
        }
    }

    // Private

    function _getCToken(IERC20 token) private pure returns(ICERC20) {
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {  // DAI
            return ICERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);  // cDAI
        } else if (token == IERC20(0)) { // ETH
            return ICERC20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);  // cETH
        } else {
            require(false, "Unsupported token");
        }
    }

    function _enterMarket(ICERC20 cToken) private {
        address[] memory tokens = new address[](1);
        tokens[0] = address(cToken);
        cToken.comptroller().enterMarkets(tokens);
    }
}