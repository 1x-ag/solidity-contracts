pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HolderBase.sol";
import "./mixins/FlashLoanAave.sol";
import "./mixins/ExchangeOneSplit.sol";
import "./mixins/ProtocolCompound.sol";
import "./mixins/OracleChainLink.sol";
//import "./mixins/OracleCompound.sol";


contract HolderOne is
    HolderBase,
    FlashLoanAave,
    ExchangeOneSplit,
    ProtocolCompound,
    OracleChainLink
    //OracleCompound
{
}
