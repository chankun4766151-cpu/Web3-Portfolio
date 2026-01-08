// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IToken.sol";

/**
 * @title StakingPool - ETH 质押池合约
 * @notice 用户可以质押 ETH 来赚取 KK Token 奖励
 * @dev 使用累积奖励系数算法实现公平的奖励分配
 * 
 * ============ 核心概念 ============
 * 
 * 1. 累积奖励系数 (accRewardPerShare)
 *    - 表示从合约开始到现在，每单位质押 ETH 累积获得的奖励
 *    - 每次有人 stake/unstake/claim 时更新
 *    - 使用 1e12 精度避免小数截断
 * 
 * 2. 奖励债务 (rewardDebt)
 *    - 记录用户"已经计算过"的奖励
 *    - 用户实际可领取的奖励 = 用户质押量 * 当前累积系数 - 用户奖励债务
 * 
 * 3. 待领取奖励 (pendingRewards)
 *    - 用户在 unstake 时结算的奖励会先存到这里
 *    - claim 时一起发放
 * 
 * ============ 公式推导 ============
 * 
 * 假设用户 A 在区块 100 质押 1 ETH，区块 110 领取奖励：
 * - 区块 100-110 产出：10 * 10 = 100 KK Token
 * - 累积系数变化：0 -> 100/1 = 100
 * - A 可领取：1 * 100 - 0 = 100 KK Token
 * 
 * 假设用户 B 在区块 105 加入质押 1 ETH：
 * - 区块 100-105 产出：10 * 5 = 50 KK Token，累积系数：50
 * - 区块 105-110 产出：10 * 5 = 50 KK Token，累积系数增加：50/2 = 25
 * - 最终累积系数：50 + 25 = 75
 * - A 可领取：1 * 75 - 0 = 75 KK Token
 * - B 可领取：1 * 75 - 50 = 25 KK Token
 * - 总计：75 + 25 = 100 KK Token ✓
 */
contract StakingPool is IStaking, ReentrancyGuard {
    /// @notice KK Token 合约地址
    IToken public immutable kkToken;

    /// @notice 每个区块产出的 KK Token 数量 (10 个，使用 18 位小数)
    uint256 public constant REWARD_PER_BLOCK = 10 ether;

    /// @notice 累积每股奖励的精度倍数（避免小数截断）
    uint256 private constant ACC_REWARD_PRECISION = 1e12;

    /// @notice 总质押的 ETH 数量
    uint256 public totalStaked;

    /// @notice 累积每股奖励（精度：1e12）
    /// @dev 表示每 1 wei ETH 从开始到现在累积的奖励
    uint256 public accRewardPerShare;

    /// @notice 上次更新奖励的区块号
    uint256 public lastRewardBlock;

    /// @notice 用户质押余额映射
    mapping(address => uint256) internal _stakedBalance;

    /// @notice 用户奖励债务映射
    /// @dev 用于计算用户实际可领取的奖励
    mapping(address => uint256) public rewardDebt;

    /// @notice 用户待领取奖励映射
    /// @dev 存储用户在 unstake 时结算的奖励
    mapping(address => uint256) public pendingRewards;

    // ============ Events ============

    /// @notice 用户质押 ETH
    event Staked(address indexed user, uint256 amount);

    /// @notice 用户赎回 ETH
    event Unstaked(address indexed user, uint256 amount);

    /// @notice 用户领取奖励
    event Claimed(address indexed user, uint256 amount);

    /// @notice 奖励池更新
    event RewardPoolUpdated(uint256 lastRewardBlock, uint256 accRewardPerShare);

    // ============ Errors ============

    error ZeroAmount();
    error InsufficientBalance();
    error TransferFailed();

    /**
     * @dev 构造函数
     * @param _kkToken KK Token 合约地址
     * 
     * 部署流程：
     * 1. 部署 KKToken
     * 2. 部署 StakingPool，传入 KKToken 地址
     * 3. 调用 KKToken.setMinter(StakingPool 地址)
     */
    constructor(address _kkToken) {
        kkToken = IToken(_kkToken);
        lastRewardBlock = block.number;
    }

    // ============ External Functions ============

    /**
     * @dev 质押 ETH
     * @notice 发送 ETH 到此函数进行质押，开始赚取 KK Token 奖励
     * 
     * 执行步骤：
     * 1. 更新全局奖励状态（计算从上次更新到现在产出的奖励）
     * 2. 如果用户之前有质押，先结算之前的奖励
     * 3. 增加用户质押余额和总质押量
     * 4. 更新用户奖励债务（防止新质押的 ETH 领取之前的奖励）
     */
    function stake() external payable virtual override nonReentrant {
        if (msg.value == 0) revert ZeroAmount();

        // 步骤 1：更新全局奖励状态
        _updateRewardPool();

        // 步骤 2：结算用户之前的奖励
        if (_stakedBalance[msg.sender] > 0) {
            uint256 pending = _calculatePendingReward(msg.sender);
            if (pending > 0) {
                pendingRewards[msg.sender] += pending;
            }
        }

        // 步骤 3：更新质押余额
        _stakedBalance[msg.sender] += msg.value;
        totalStaked += msg.value;

        // 步骤 4：更新奖励债务
        // 新的奖励债务 = 新的质押总量 * 当前累积系数
        // 这样可以确保用户只能领取质押后产生的奖励
        rewardDebt[msg.sender] = (_stakedBalance[msg.sender] * accRewardPerShare) / ACC_REWARD_PRECISION;

        emit Staked(msg.sender, msg.value);
    }

    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量（单位：wei）
     * @notice 赎回时会自动结算奖励到 pendingRewards
     * 
     * 执行步骤：
     * 1. 更新全局奖励状态
     * 2. 结算用户奖励到 pendingRewards
     * 3. 减少用户质押余额和总质押量
     * 4. 更新用户奖励债务
     * 5. 转回 ETH 给用户
     */
    function unstake(uint256 amount) external virtual override nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (_stakedBalance[msg.sender] < amount) revert InsufficientBalance();

        // 步骤 1：更新全局奖励状态
        _updateRewardPool();

        // 步骤 2：结算用户奖励
        uint256 pending = _calculatePendingReward(msg.sender);
        if (pending > 0) {
            pendingRewards[msg.sender] += pending;
        }

        // 步骤 3：更新质押余额
        _stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;

        // 步骤 4：更新奖励债务
        rewardDebt[msg.sender] = (_stakedBalance[msg.sender] * accRewardPerShare) / ACC_REWARD_PRECISION;

        // 步骤 5：转回 ETH
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev 领取 KK Token 奖励
     * @notice 将累积的奖励（包括 pendingRewards 和当前可领取的）一起发放
     * 
     * 执行步骤：
     * 1. 更新全局奖励状态
     * 2. 计算当前可领取的奖励
     * 3. 加上之前存储的 pendingRewards
     * 4. 更新奖励债务
     * 5. 铸造 KK Token 给用户
     */
    function claim() external override nonReentrant {
        // 步骤 1：更新全局奖励状态
        _updateRewardPool();

        // 步骤 2：计算当前可领取的奖励
        uint256 pending = _calculatePendingReward(msg.sender);

        // 步骤 3：加上之前存储的 pendingRewards
        uint256 totalReward = pending + pendingRewards[msg.sender];
        
        if (totalReward == 0) revert ZeroAmount();

        // 步骤 4：重置 pendingRewards 并更新奖励债务
        pendingRewards[msg.sender] = 0;
        rewardDebt[msg.sender] = (_stakedBalance[msg.sender] * accRewardPerShare) / ACC_REWARD_PRECISION;

        // 步骤 5：铸造 KK Token
        kkToken.mint(msg.sender, totalReward);

        emit Claimed(msg.sender, totalReward);
    }

    // ============ View Functions ============

    /**
     * @dev 获取用户质押的 ETH 数量
     * @param account 用户地址
     * @return 质押的 ETH 数量（单位：wei）
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _stakedBalance[account];
    }

    /**
     * @dev 获取用户待领取的 KK Token 奖励
     * @param account 用户地址
     * @return 待领取的 KK Token 数量
     * 
     * 计算逻辑：
     * 1. 先计算如果现在更新奖励池，累积系数会是多少
     * 2. 用新的累积系数计算用户可领取的奖励
     * 3. 加上 pendingRewards 中存储的奖励
     */
    function earned(address account) external view override returns (uint256) {
        uint256 _accRewardPerShare = accRewardPerShare;
        
        // 如果有新的区块产出，计算新的累积系数
        if (block.number > lastRewardBlock && totalStaked > 0) {
            uint256 blockDiff = block.number - lastRewardBlock;
            uint256 reward = blockDiff * REWARD_PER_BLOCK;
            _accRewardPerShare += (reward * ACC_REWARD_PRECISION) / totalStaked;
        }

        // 计算用户可领取的奖励
        uint256 pending = (_stakedBalance[account] * _accRewardPerShare) / ACC_REWARD_PRECISION - rewardDebt[account];
        
        return pending + pendingRewards[account];
    }

    // ============ Internal Functions ============

    /**
     * @dev 更新奖励池状态
     * @notice 计算从上次更新到现在产出的奖励，并更新累积系数
     * 
     * 核心公式：
     * 新累积系数 = 旧累积系数 + (区块差 * 每区块奖励) / 总质押量
     * 
     * 注意事项：
     * - 如果没有人质押，不更新累积系数（避免除以零）
     * - 使用 ACC_REWARD_PRECISION 提高精度
     */
    function _updateRewardPool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        // 计算区块差和产出的奖励
        uint256 blockDiff = block.number - lastRewardBlock;
        uint256 reward = blockDiff * REWARD_PER_BLOCK;

        // 更新累积系数
        // 乘以 ACC_REWARD_PRECISION 是为了保持精度
        accRewardPerShare += (reward * ACC_REWARD_PRECISION) / totalStaked;
        lastRewardBlock = block.number;

        emit RewardPoolUpdated(lastRewardBlock, accRewardPerShare);
    }

    /**
     * @dev 计算用户当前可领取的奖励（不包括 pendingRewards）
     * @param account 用户地址
     * @return 可领取的奖励数量
     * 
     * 公式：用户质押量 * 累积系数 / 精度 - 用户奖励债务
     */
    function _calculatePendingReward(address account) internal view returns (uint256) {
        return (_stakedBalance[account] * accRewardPerShare) / ACC_REWARD_PRECISION - rewardDebt[account];
    }

    /**
     * @dev 允许合约接收 ETH（用于测试或意外转入）
     */
    receive() external payable {}
}
