pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./IHolder.sol";
import "./HolderProxy.sol";
import "./lib/UniversalERC20.sol";


contract OneLeverage is ERC20, ERC20Detailed {

    using UniversalERC20 for IERC20;

    IERC20 public collateral;
    IERC20 public debt;
    uint256 public leverage;

    mapping(address => IHolder) public holders;

    event OpenPosition(
        address indexed owner,
        uint256 amount,
        uint256 stopLoss,
        uint256 takeProfit
    );

    event ClosePosition(
        address indexed owner,
        uint256 pnl
    );

    constructor(
        string memory name,
        string memory symbol,
        IERC20 collateralToken,
        IERC20 debtToken,
        uint256 leverageRatio
    )
        public
        ERC20Detailed(name, symbol, 18)
    {
        require(leverageRatio > 1, "Leverage ratio is too small");
        require(leverageRatio <= 10, "Leverage ratio is too huge");

        collateral = collateralToken;
        debt = debtToken;
        leverage = leverageRatio;
    }

    function upgradeHolder(address newDelegate) public {
        HolderProxy holder = HolderProxy(address(uint160(address(getOrCreateHolder(msg.sender)))));
        require(newDelegate != address(0) && newDelegate != holder.delegate());
        holder.upgradeDelegate(newDelegate);
    }

    function arbitraryCall(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable {
        IHolder holder = getOrCreateHolder(msg.sender);

        for (uint i = 0; i < tokens.length; i++) {
            tokens[i].universalTransferFrom(msg.sender, address(this), amounts[i]);
            tokens[i].universalInfiniteApproveIfNeeded(address(holder));
        }

        (bool success,) = address(holder).call.value(msg.value)(abi.encodePacked(
            data,
            collateral,
            debt,
            leverage
        ));
        require(success);
    }

    function openPosition(
        address newDelegate,
        uint256 amount,
        uint256 stopLoss,
        uint256 takeProfit,
        uint256 minReturn
    ) external payable {
        debt.universalTransferFrom(msg.sender, address(this), amount);

        IHolder holder = getOrCreateHolder(msg.sender);
        if (holder.delegate() == address(0)) {
            upgradeHolder(newDelegate);
        }

        require(holder.borrowAmount(debt) == 0, "Can't open second position");
        if (balanceOf(msg.sender) > 0) {
            _burn(msg.sender, balanceOf(msg.sender));
            emit ClosePosition(msg.sender, 0);
        }

        debt.universalInfiniteApproveIfNeeded(address(holder));

        uint256 balance = holder.openPosition.value(msg.value)(collateral, debt, leverage, amount, minReturn, stopLoss, takeProfit);
        _mint(msg.sender, balance);
        emit OpenPosition(msg.sender, balance, stopLoss, takeProfit);
    }

    function closePosition(uint256 minReturn) external {
        closePositionFor(msg.sender, minReturn);
    }

    function closePositionFor(
        address user,
        uint256 minReturn
    ) public {
        require(balanceOf(user) != 0, "Can't close non-existing position");

        IHolder holder = getOrCreateHolder(user);
        uint256 pnl = holder.pnl(collateral, debt, leverage);
        require(
            msg.sender == user
            || (
                holder.stopLoss() != 0 &&
                holder.stopLoss() <= pnl
            )
            || (
                holder.takeProfit() != 0 &&
                holder.takeProfit() >= pnl
            ),
            "Can close own position or position available for liquidation"
        );

        holder.closePosition(collateral, debt, user, minReturn);
        _burn(user, balanceOf(user));
        emit ClosePosition(user, pnl);
    }

    // Internal

    function getOrCreateHolder(address user) internal returns (IHolder) {
        IHolder holder = holders[user];
        if (holder == IHolder(0)) {
            holder = IHolder(address(new HolderProxy()));
            holders[user] = holder;
        }
        return holder;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(amount == balanceOf(from) && balanceOf(to) == 0, "CDP can't be partially moved");
        super._transfer(from, to, amount);
    }
}