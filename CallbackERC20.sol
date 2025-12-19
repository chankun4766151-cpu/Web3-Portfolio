// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice ERC20 扩展：支持 transferWithCallback(to, value, data)
 * - 如果 to 是合约地址，则会回调 ITokenReceiver(to).tokensReceived(...)
 */
interface ITokenReceiver {
    function tokensReceived(address operator, address from, uint256 value, bytes calldata data) external;
}

contract CallbackERC20 is ERC20, Ownable {
    using Address for address;

    mapping(address => bool) public executor;

    event ExecutorUpdated(address indexed executor, bool allowed);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Ownable(msg.sender) // OZ 5.x
    {}

    modifier onlyExecutor() {
        require(executor[msg.sender], "executor: not allowed");
        _;
    }

    function setExecutor(address executor_, bool allowed) external onlyOwner {
        executor[executor_] = allowed;
        emit ExecutorUpdated(executor_, allowed);
    }

    function mint(address to, uint256 amount) external onlyExecutor returns (bool) {
        _mint(to, amount);
        return true;
    }

    /// @notice 扩展转账：带 data 参数，并在接收方为合约时触发回调
    function transferWithCallback(
    address to,
    uint256 value,
    bytes calldata data
) external returns (bool) {
    _transfer(msg.sender, to, value);

    try ITokenReceiver(to).tokensReceived(
        msg.sender,
        msg.sender,
        value,
        data
    ) {
        // callback ok
    } catch {
        // 非合约 or 不实现接口，忽略
    }

    return true;
}

    }
