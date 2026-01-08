// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StakingPool.sol";
import "./interfaces/IWrappedTokenGateway.sol";

/**
 * @title StakingPoolWithAave - 集成 Aave 的 ETH 质押池
 * @notice 用户质押的 ETH 会被存入 Aave 赚取利息（加分项功能）
 * @dev 继承 StakingPool，覆盖 stake 和 unstake 方法
 * 
 * ============ 设计思路 ============
 * 
 * 1. 利息归属
 *    - 质押的 ETH 存入 Aave 会产生利息
 *    - 利息由 aWETH 余额增长体现
 *    - 本实现中，利息归合约所有者（可修改为分配给用户）
 * 
 * 2. 工作流程
 *    stake:  用户 ETH -> Gateway -> Aave Pool -> aWETH 给合约
 *    unstake: aWETH approve -> Gateway -> 用户收到 ETH
 * 
 * 3. 安全考虑
 *    - 使用 ReentrancyGuard 防止重入攻击
 *    - 提前 approve 给 Gateway 避免每次操作都 approve
 * 
 * ============ 部署说明 ============
 * 
 * Sepolia 地址：
 * - Pool: 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951
 * - WrappedTokenGateway: 0x387d311e47e80b498169e6fb51d3193167d89F7D
 * - aWETH: 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c
 * 
 * Mainnet 地址：
 * - Pool: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2
 * - WrappedTokenGateway: 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C
 * - aWETH: 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8
 */
contract StakingPoolWithAave is StakingPool {
    /// @notice Aave V3 Pool 地址
    address public immutable aavePool;

    /// @notice Aave WrappedTokenGateway 地址
    IWrappedTokenGateway public immutable wethGateway;

    /// @notice aWETH 代币地址
    IERC20Minimal public immutable aWETH;

    /// @notice 合约所有者（收取 Aave 利息）
    address public owner;

    /// @notice Gateway 是否已被授权
    bool private gatewayApproved;

    // ============ Events ============

    event DepositedToAave(uint256 amount);
    event WithdrawnFromAave(uint256 amount);
    event InterestWithdrawn(address indexed to, uint256 amount);

    // ============ Errors ============

    error OnlyOwner();

    /**
     * @dev 构造函数
     * @param _kkToken KK Token 合约地址
     * @param _aavePool Aave V3 Pool 地址
     * @param _wethGateway Aave WrappedTokenGateway 地址
     * @param _aWETH aWETH 代币地址
     */
    constructor(
        address _kkToken,
        address _aavePool,
        address _wethGateway,
        address _aWETH
    ) StakingPool(_kkToken) {
        aavePool = _aavePool;
        wethGateway = IWrappedTokenGateway(_wethGateway);
        aWETH = IERC20Minimal(_aWETH);
        owner = msg.sender;
    }

    /**
     * @dev 质押 ETH（覆盖父合约方法）
     * @notice 用户质押的 ETH 会被存入 Aave 赚取利息
     * 
     * 执行步骤：
     * 1. 更新全局奖励状态
     * 2. 结算用户之前的奖励
     * 3. 更新质押余额
     * 4. 更新奖励债务
     * 5. 将 ETH 存入 Aave
     */
    function stake() external payable override nonReentrant {
        if (msg.value == 0) revert ZeroAmount();

        // 更新奖励池
        _updateRewardPool();

        // 结算之前的奖励
        if (_stakedBalance[msg.sender] > 0) {
            uint256 pending = _calculatePendingReward(msg.sender);
            if (pending > 0) {
                pendingRewards[msg.sender] += pending;
            }
        }

        // 更新质押余额
        _stakedBalance[msg.sender] += msg.value;
        totalStaked += msg.value;

        // 更新奖励债务
        rewardDebt[msg.sender] = (_stakedBalance[msg.sender] * accRewardPerShare) / 1e12;

        // 将 ETH 存入 Aave
        _depositToAave(msg.value);

        emit Staked(msg.sender, msg.value);
    }

    /**
     * @dev 赎回质押的 ETH（覆盖父合约方法）
     * @param amount 赎回数量
     * @notice 从 Aave 取出 ETH 并返还给用户
     */
    function unstake(uint256 amount) external override nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (_stakedBalance[msg.sender] < amount) revert InsufficientBalance();

        // 更新奖励池
        _updateRewardPool();

        // 结算奖励
        uint256 pending = _calculatePendingReward(msg.sender);
        if (pending > 0) {
            pendingRewards[msg.sender] += pending;
        }

        // 更新质押余额
        _stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;

        // 更新奖励债务
        rewardDebt[msg.sender] = (_stakedBalance[msg.sender] * accRewardPerShare) / 1e12;

        // 从 Aave 取出 ETH 并转给用户
        _withdrawFromAave(amount, msg.sender);

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev 提取 Aave 产生的利息（仅限所有者）
     * @notice 利息 = aWETH 余额 - 总质押量
     * 
     * 示例：
     * - 总质押：100 ETH
     * - aWETH 余额：101 ETH
     * - 利息：1 ETH
     */
    function withdrawInterest() external {
        if (msg.sender != owner) revert OnlyOwner();

        uint256 aWETHBalance = aWETH.balanceOf(address(this));
        uint256 interest = aWETHBalance > totalStaked ? aWETHBalance - totalStaked : 0;
        
        if (interest > 0) {
            _withdrawFromAave(interest, owner);
            emit InterestWithdrawn(owner, interest);
        }
    }

    /**
     * @dev 查看当前累积的利息
     * @return 累积的利息数量
     */
    function accumulatedInterest() external view returns (uint256) {
        uint256 aWETHBalance = aWETH.balanceOf(address(this));
        return aWETHBalance > totalStaked ? aWETHBalance - totalStaked : 0;
    }

    // ============ Internal Functions ============

    /**
     * @dev 将 ETH 存入 Aave
     * @param amount 存入数量
     */
    function _depositToAave(uint256 amount) internal {
        wethGateway.depositETH{value: amount}(aavePool, address(this), 0);
        emit DepositedToAave(amount);
    }

    /**
     * @dev 从 Aave 取出 ETH
     * @param amount 取出数量
     * @param to 接收地址
     */
    function _withdrawFromAave(uint256 amount, address to) internal {
        // 确保 Gateway 已被授权
        if (!gatewayApproved) {
            aWETH.approve(address(wethGateway), type(uint256).max);
            gatewayApproved = true;
        }

        wethGateway.withdrawETH(aavePool, amount, to);
        emit WithdrawnFromAave(amount);
    }
}
