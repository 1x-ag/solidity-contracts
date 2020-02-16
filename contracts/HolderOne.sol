pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HolderBase.sol";
import "./FlashLoanAave.sol";
import "./ExchangeOneSplit.sol";
import "./ProtocolCompound.sol";


contract HolderOne is
    HolderBase,
    FlashLoanAave,
    ExchangeOneSplit,
    ProtocolCompound
{
}
