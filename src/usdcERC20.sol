pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract testERC20 is Ownable, ERC20 {
    using SafeERC20 for IERC20;

    // executor role
    mapping(address => bool) public executor;

    constructor(
        string memory name_,
        string memory symbol_
    )
        ERC20(name_, symbol_)
        Ownable(msg.sender)   // ✅ 关键修复
    {}

    function setExecutor(address _address, bool _type)
        external
        onlyOwner
        returns (bool)
    {
        executor[_address] = _type;
        return true;
    }

    modifier onlyExecutor() {
        require(executor[msg.sender], "executor: caller is not the executor");
        _;
    }

    function mint(address account_, uint256 amount_)
        external
        onlyExecutor
        returns (bool)
    {
        _mint(account_, amount_);
        return true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
