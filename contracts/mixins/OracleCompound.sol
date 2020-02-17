pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/compound/ICERC20.sol";
import "../IHolder.sol";
import "./CompoundUtils.sol";


contract OracleCompound is IIOracle, CompoundUtils {
    function _getPrice(IERC20 token) internal view returns (uint256) {
        ICERC20 cToken = _getCToken(token);
        IPriceOracle oracle = cToken.comptroller().oracle();
        return oracle.getUnderlyingPrice(address(cToken));
    }
}
