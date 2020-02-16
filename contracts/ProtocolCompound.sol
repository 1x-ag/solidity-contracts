pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/compound/ICERC20.sol";
import "./interface/compound/ICompoundController.sol";
import "./UniversalERC20.sol";
import "./CompoundUtils.sol";
import "./OracleChainLink.sol";


contract ProtocolCompound is CompoundUtils, OracleChainLink {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    function collateralAmount(IERC20 token) public returns(uint256) {
        return _getCToken(token).balanceOfUnderlying(address(this));
    }

    function borrowAmount(IERC20 token) public returns(uint256) {
        return _getCToken(token).borrowBalanceCurrent(address(this));
    }

    function _pnl(IERC20 collateral, IERC20 debt) internal returns(uint256) {
        return _getPrice(collateral).mul(collateralAmount(collateral))
            .mul(1e18)
            .div(
                _getPrice(debt).mul(borrowAmount(debt))
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

    function _enterMarket(ICERC20 cToken) private {
        address[] memory tokens = new address[](1);
        tokens[0] = address(cToken);
        cToken.comptroller().enterMarkets(tokens);
    }
}
