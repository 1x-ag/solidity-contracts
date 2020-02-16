pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/chainlink/IAggregator.sol";
import "./UniversalERC20.sol";


contract OracleChainLink {
    using UniversalERC20 for IERC20;

    function getChainLinkOracleByToken(IERC20 token) private pure returns (IAggregator) {
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {  // DAI
            return IAggregator(0x037E8F2125bF532F3e228991e051c8A7253B642c);
        } else {
            revert("Unsupported token");
        }
    }

    function _getPrice(IERC20 token) internal view returns (uint256) {
        if (token.isETH()) {
            return 1e18;
        }

        return uint256(getChainLinkOracleByToken(token).latestAnswer());
    }
}
