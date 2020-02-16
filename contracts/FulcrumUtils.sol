pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/fulcrum/IToken.sol";
import "./UniversalERC20.sol";


contract FulcrumUtils {
    using UniversalERC20 for IERC20;

    function _getIToken(IERC20 token) internal pure returns(ICERC20) {
        if (token.isETH()) { // ETH
            return IToken(0x77f973FCaF871459aa58cd81881Ce453759281bC);
        }
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {  // DAI
            return IToken(0x493C57C4763932315A328269E1ADaD09653B9081);
        }
        if (token == IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862)) {  // REP
            return IToken(0xBd56E9477Fc6997609Cf45F84795eFbDAC642Ff1);
        }
        if (token == IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {  // USDC
            return IToken(0xF013406A0B1d544238083DF0B93ad0d2cBE0f65f);
        }
        if (token == IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) {  // WBTC
            return IToken(0xBA9262578EFef8b3aFf7F60Cd629d6CC8859C8b5);
        }
        if (token == IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498)) {  // ZRX
            return IToken(0xA7Eb2bc82df18013ecC2A6C533fc29446442EDEe);
        }

        revert("Unsupported token");
    }
}
