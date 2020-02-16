pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./IHolder.sol";
import "./HolderProxy.sol";


contract OneLeverage is ERC20, ERC20Detailed {

    IERC20 public collateral;
    IERC20 public debt;
    uint256 public leverage;

    mapping(address => IHolder) public holders;

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

    function openPosition(uint256 amount, address newDelegate) external payable {
        require(balanceOf(msg.sender) == 0, "Can't open second position");

        IHolder holder = getOrCreateHolder(msg.sender);
        if (newDelegate != address(0)) {
            HolderProxy(address(uint160(address(holder)))).upgradeDelegate(newDelegate);
        }
        uint256 balance = holder.openPosition.value(msg.value)(collateral, debt, amount, leverage);
        _mint(msg.sender, balance);
    }

    function closePosition(address newDelegate) external {
        require(balanceOf(msg.sender) != 0, "Can't close non-existing position");

        IHolder holder = getOrCreateHolder(msg.sender);
        if (newDelegate != address(0)) {
            HolderProxy(address(uint160(address(holder)))).upgradeDelegate(newDelegate);
        }
        holder.closePosition(collateral, debt, msg.sender);
        _burn(msg.sender, balanceOf(msg.sender));
    }

    // Internal

    function getOrCreateHolder(address user) internal returns(IHolder) {
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