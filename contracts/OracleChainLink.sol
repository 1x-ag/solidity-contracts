pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/chainlink/IAggregator.sol";
import "./UniversalERC20.sol";


contract OracleChainLink {
    using UniversalERC20 for IERC20;

    function getChainLinkOracleByToken(IERC20 token) private pure returns (IAggregator) {
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {  // DAI
            return IAggregator(0x037E8F2125bF532F3e228991e051c8A7253B642c);
        }
        if (token == IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF)) {  // BAT
            return IAggregator(0x9b4e2579895efa2b4765063310Dc4109a7641129);
        }
        if (token == IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862)) {  // REP
            return IAggregator(0xb8b513d9cf440C1b6f5C7142120d611C94fC220c);
        }
        if (token == IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) {  // USDC
            return IAggregator(0xdE54467873c3BCAA76421061036053e371721708);
        }
        if (token == IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) {  // WBTC
            return IAggregator(0x0133Aa47B6197D0BA090Bf2CD96626Eb71fFd13c);
        }
        if (token == IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498)) {  // ZRX
            return IAggregator(0xA0F9D94f060836756FFC84Db4C78d097cA8C23E8);
        }

        revert("Unsupported token");
    }

    function _getPrice(IERC20 token) internal view returns (uint256) {
        if (token.isETH()) {
            return 1e18;
        }

        return uint256(getChainLinkOracleByToken(token).latestAnswer());
    }
}
