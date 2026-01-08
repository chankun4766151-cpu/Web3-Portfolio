// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IToken.sol";

/**
 * @title KKToken - 质押奖励代币
 * @notice ERC20 代币，由 StakingPool 合约铸造作为质押奖励
 * @dev 继承 OpenZeppelin 的 ERC20 和 Ownable
 * 
 * 设计说明：
 * - 只有 StakingPool 合约（minter）可以调用 mint 函数
 * - Owner 可以设置 minter 地址
 * - 代币没有最大供应量限制，由 StakingPool 按区块产出
 */
contract KKToken is ERC20, Ownable, IToken {
    /// @notice 授权的铸造者地址（StakingPool 合约）
    address public minter;

    /// @notice 当 minter 地址更新时触发
    event MinterUpdated(address indexed oldMinter, address indexed newMinter);

    /// @notice 错误：调用者不是 minter
    error OnlyMinter();

    /**
     * @dev 构造函数
     * @param initialOwner 合约所有者地址
     */
    constructor(address initialOwner) ERC20("KK Token", "KK") Ownable(initialOwner) {}

    /**
     * @dev 设置 minter 地址
     * @param _minter 新的 minter 地址（通常是 StakingPool 合约）
     * @notice 只有 owner 可以调用此函数
     * 
     * 为什么需要这个函数？
     * - 部署时无法知道 StakingPool 的地址（先有鸡还是先有蛋的问题）
     * - 需要在部署 StakingPool 后设置 minter
     */
    function setMinter(address _minter) external onlyOwner {
        address oldMinter = minter;
        minter = _minter;
        emit MinterUpdated(oldMinter, _minter);
    }

    /**
     * @dev 铸造代币
     * @param to 接收代币的地址
     * @param amount 铸造数量
     * @notice 只有 minter（StakingPool）可以调用
     * 
     * 安全说明：
     * - 使用自定义错误而非 require 节省 Gas
     * - minter 应该是一个经过审计的合约，控制铸造逻辑
     */
    function mint(address to, uint256 amount) external override {
        if (msg.sender != minter) revert OnlyMinter();
        _mint(to, amount);
    }
}
