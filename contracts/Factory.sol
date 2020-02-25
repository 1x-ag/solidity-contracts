pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./OneLeverage.sol";
import "./lib/UniversalERC20.sol";


contract Factory {

    using UniversalERC20 for IERC20;

    mapping(address => mapping(address => mapping(uint256 => OneLeverage))) public assets;

    event NewLeverageToken(
        address indexed token,
        address collateral,
        address debt,
        uint256 leverage
    );

    function openPosition(
        address newDelegate,
        IERC20 collateral,
        IERC20 debt,
        uint256 leverage,
        uint256 amount,
        uint256 minReturn,
        uint256 stopLoss,
        uint256 takeProfit
    ) public payable {
        debt.universalTransferFrom(msg.sender, address(this), amount);

        OneLeverage one = assets[address(collateral)][address(debt)][leverage];
        if (one == OneLeverage(0)) {
            string memory collateralSymbol = collateral.universalSymbol();
            string memory debtSymbol = debt.universalSymbol();
            one = new OneLeverage(
                string(abi.encodePacked("1x.ag ", uint8(48 + leverage), "x ", collateralSymbol, debtSymbol)),
                string(abi.encodePacked(uint8(48 + leverage), "x", collateralSymbol, debtSymbol)),
                collateral,
                debt,
                leverage
            );
            assets[address(collateral)][address(debt)][leverage] = one;

            emit NewLeverageToken(
                address(one),
                address(collateral),
                address(debt),
                leverage
            );
        }

        debt.universalInfiniteApproveIfNeeded(address(one));
        one.openPosition.value(msg.value)(
            newDelegate,
            amount,
            stopLoss,
            takeProfit,
            minReturn
        );

        IERC20(one).universalTransfer(msg.sender, one.balanceOf(address(this)));
    }
}
