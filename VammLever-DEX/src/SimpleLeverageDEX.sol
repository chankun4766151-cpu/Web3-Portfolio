// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimpleLeverageDEX
 * @dev 基于 vAMM 的简单杠杆 DEX 实现
 * 
 * ==================== vAMM 核心原理 ====================
 * 
 * vAMM (虚拟自动做市商) 使用虚拟储备来计算价格：
 * - vETHAmount: 虚拟 ETH 储备量
 * - vUSDCAmount: 虚拟 USDC 储备量
 * - vK: 恒定乘积 (vETH * vUSDC = K)
 * 
 * 与传统 AMM 的区别：
 * 1. 无需真实流动性提供者
 * 2. 虚拟储备仅用于价格计算
 * 3. 用户的保证金是真实资金
 * 
 * 价格计算公式：price = vUSDCAmount / vETHAmount
 */
contract SimpleLeverageDEX {

    uint public vK;           // 恒定乘积常数 (vETH * vUSDC = K)
    uint public vETHAmount;   // 虚拟 ETH 储备
    uint public vUSDCAmount;  // 虚拟 USDC 储备

    IERC20 public USDC;       // USDC 代币合约

    /**
     * @dev 用户头寸信息结构
     * @param margin 保证金 - 用户实际存入的 USDC 金额
     * @param borrowed 借入金额 - 杠杆放大的部分 (amount - margin)
     * @param position 虚拟 ETH 头寸
     *        - 正数: 做多（买入 ETH）
     *        - 负数: 做空（卖出 ETH）
     *        - 零: 无头寸
     */
    struct PositionInfo {
        uint256 margin;       // 保证金 (真实的 USDC)
        uint256 borrowed;     // 借入的资金
        uint256 usdcFromSale; // 做空时卖出 ETH 获得的 USDC (用于计算做空 PnL)
        int256 position;      // 虚拟 ETH 持仓
    }
    
    mapping(address => PositionInfo) public positions;

    // 事件定义
    event PositionOpened(address indexed user, uint256 margin, uint level, bool long, int256 position);
    event PositionClosed(address indexed user, int256 pnl, uint256 payout);
    event PositionLiquidated(address indexed user, address indexed liquidator, int256 pnl);

    /**
     * @dev 构造函数 - 初始化虚拟储备
     * @param vEth 初始虚拟 ETH 数量
     * @param vUSDC 初始虚拟 USDC 数量
     * @param _usdc USDC 代币合约地址
     * 
     * 示例: vEth=1000, vUSDC=100000 表示初始价格为 100 USDC/ETH
     */
    constructor(uint vEth, uint vUSDC, address _usdc) {
        vETHAmount = vEth;
        vUSDCAmount = vUSDC;
        vK = vEth * vUSDC;  // 恒定乘积 K
        USDC = IERC20(_usdc);
    }

    /**
     * @dev 获取当前 ETH 价格
     * @return 当前 1 ETH 的 USDC 价格
     */
    function getPrice() public view returns (uint256) {
        return vUSDCAmount * 1e18 / vETHAmount;
    }

    /**
     * ==================== 开启杠杆头寸 ====================
     * @param _margin 保证金金额 (USDC)
     * @param level 杠杆倍数 (例如: 2 表示 2x 杠杆)
     * @param long 方向 (true = 做多, false = 做空)
     * 
     * 做多 (Long) 原理：
     * - 用户看涨 ETH，希望 ETH 价格上涨
     * - 用 USDC 购买虚拟 ETH
     * - 如果 ETH 涨价，平仓时能换回更多 USDC → 盈利
     * 
     * 做空 (Short) 原理：
     * - 用户看跌 ETH，希望 ETH 价格下跌
     * - 先借入虚拟 ETH 并卖掉换成 USDC
     * - 如果 ETH 跌价，回购 ETH 成本更低 → 盈利
     */
    function openPosition(uint256 _margin, uint level, bool long) external {
        require(positions[msg.sender].position == 0, "Position already open");
        require(level >= 1 && level <= 10, "Invalid leverage level");
        require(_margin > 0, "Margin must be positive");

        PositionInfo storage pos = positions[msg.sender];

        // 从用户转入保证金
        USDC.transferFrom(msg.sender, address(this), _margin);
        
        // 计算总交易金额 = 保证金 × 杠杆倍数
        uint amount = _margin * level;
        uint256 borrowAmount = amount - _margin;  // 借入金额 = 总金额 - 保证金

        pos.margin = _margin;
        pos.borrowed = borrowAmount;

        if (long) {
            // ========== 做多逻辑 ==========
            // 原理: 用 USDC 购买虚拟 ETH
            // 
            // 根据恒定乘积公式: vETH * vUSDC = K
            // 新的 vUSDC = 原 vUSDC + 投入金额
            // 新的 vETH = K / 新的 vUSDC
            // 买到的 ETH = 原 vETH - 新的 vETH
            
            uint newVUSDC = vUSDCAmount + amount;
            uint newVETH = vK / newVUSDC;
            uint256 ethBought = vETHAmount - newVETH;
            
            // 更新虚拟储备
            vUSDCAmount = newVUSDC;
            vETHAmount = newVETH;
            
            // 记录正数头寸表示做多
            pos.position = int256(ethBought);
        } else {
            // ========== 做空逻辑 ==========
            // 原理: 先计算 amount 的 USDC 等值多少 ETH，然后卖出这些 ETH
            // 
            // 首先计算要卖出多少 ETH 才能得到 amount 的 USDC 效果
            // 使用公式: 卖出 ETH 后，vUSDC 减少，vETH 增加
            // 
            // 简化计算: 按当前价格计算等值的 ETH 数量
            // ETH 数量 = amount * vETHAmount / vUSDCAmount
            
            uint256 ethToSell = amount * vETHAmount / vUSDCAmount;
            uint newVETH = vETHAmount + ethToSell;
            uint newVUSDC = vK / newVETH;
            
            // 卖出 ETH 获得的 USDC
            uint256 usdcReceived = vUSDCAmount - newVUSDC;
            pos.usdcFromSale = usdcReceived;
            
            // 更新虚拟储备
            vETHAmount = newVETH;
            vUSDCAmount = newVUSDC;
            
            // 记录负数头寸表示做空
            pos.position = -int256(ethToSell);
        }
        
        emit PositionOpened(msg.sender, _margin, level, long, pos.position);
    }

    /**
     * ==================== 计算盈亏 (PnL) ====================
     * @param user 用户地址
     * @return pnl 盈亏金额 (正数为盈利，负数为亏损)
     * 
     * 计算原理:
     * 1. 做多时: 
     *    - 持有正数 ETH 头寸
     *    - 按当前价格卖出 ETH 能获得的 USDC
     *    - PnL = 卖出获得的 USDC - 借入的金额
     * 
     * 2. 做空时:
     *    - 持有负数 ETH 头寸 (欠 ETH)
     *    - 按当前价格买回 ETH 需要的 USDC
     *    - PnL = 当初卖出获得的 USDC - 买回需要的 USDC
     */
    function calculatePnL(address user) public view returns (int256) {
        PositionInfo memory pos = positions[user];
        
        if (pos.position == 0) {
            return 0;
        }
        
        if (pos.position > 0) {
            // ========== 做多头寸的 PnL 计算 ==========
            // 计算卖出 ETH 能得到多少 USDC
            uint256 ethAmount = uint256(pos.position);
            
            // 模拟卖出: vETH 增加, vUSDC 减少
            uint newVETH = vETHAmount + ethAmount;
            uint newVUSDC = vK / newVETH;
            uint256 usdcReceived = vUSDCAmount - newVUSDC;
            
            // PnL = 卖出获得的 USDC - 借入的金额
            return int256(usdcReceived) - int256(pos.borrowed);
        } else {
            // ========== 做空头寸的 PnL 计算 ==========
            // 计算买回 ETH 需要多少 USDC
            uint256 ethAmount = uint256(-pos.position);
            
            // 模拟买入: vUSDC 增加, vETH 减少
            uint newVETH = vETHAmount - ethAmount;
            require(newVETH > 0, "Insufficient liquidity");
            uint newVUSDC = vK / newVETH;
            uint256 usdcNeeded = newVUSDC - vUSDCAmount;
            
            // PnL = 卖出 ETH 获得的 USDC - 买回需要的 USDC
            // 如果价格下跌了，买回 ETH 更便宜，usdcFromSale > usdcNeeded，盈利
            return int256(pos.usdcFromSale) - int256(usdcNeeded);
        }
    }

    /**
     * ==================== 关闭头寸并结算 ====================
     * 
     * 平仓流程:
     * 1. 计算当前 PnL
     * 2. 反向操作恢复虚拟储备
     * 3. 计算用户应得金额: margin + PnL
     * 4. 转账给用户（不考虑协议亏损，最少返回 0）
     */
    function closePosition() external {
        PositionInfo memory pos = positions[msg.sender];
        require(pos.position != 0, "No open position");
        
        // 计算盈亏
        int256 pnl = calculatePnL(msg.sender);
        
        // 恢复虚拟储备（反向操作）
        if (pos.position > 0) {
            // 做多平仓: 卖出 ETH 换回 USDC
            uint256 ethAmount = uint256(pos.position);
            vETHAmount = vETHAmount + ethAmount;
            vUSDCAmount = vK / vETHAmount;
        } else {
            // 做空平仓: 买回 ETH
            uint256 ethAmount = uint256(-pos.position);
            vETHAmount = vETHAmount - ethAmount;
            vUSDCAmount = vK / vETHAmount;
        }
        
        // 计算用户应得金额
        // 用户最终获得 = 保证金 + PnL
        // 注意: 不考虑协议亏损，所以最少返回 0
        int256 payout = int256(pos.margin) + pnl;
        
        // 删除头寸
        delete positions[msg.sender];
        
        // 转账给用户
        if (payout > 0) {
            USDC.transfer(msg.sender, uint256(payout));
        }
        
        emit PositionClosed(msg.sender, pnl, payout > 0 ? uint256(payout) : 0);
    }

    /**
     * ==================== 清算头寸 ====================
     * @param _user 被清算用户地址
     * 
     * 清算条件:
     * - 清算人不能是头寸持有者本人
     * - 亏损必须超过保证金的 80%
     * 
     * 清算原理:
     * - 当用户亏损过大时，为防止协议损失，允许第三方清算
     * - 清算人获得被清算用户剩余的保证金作为奖励
     */
    function liquidatePosition(address _user) external {
        PositionInfo memory position = positions[_user];
        require(position.position != 0, "No open position");
        require(msg.sender != _user, "Cannot liquidate yourself");
        
        int256 pnl = calculatePnL(_user);
        
        // 检查清算条件: 亏损 > 保证金的 80%
        // 即: -pnl > margin * 80 / 100
        require(pnl < 0 && uint256(-pnl) > position.margin * 80 / 100, 
                "Position not liquidatable");
        
        // 恢复虚拟储备（与 closePosition 相同的逻辑）
        if (position.position > 0) {
            uint256 ethAmount = uint256(position.position);
            vETHAmount = vETHAmount + ethAmount;
            vUSDCAmount = vK / vETHAmount;
        } else {
            uint256 ethAmount = uint256(-position.position);
            vETHAmount = vETHAmount - ethAmount;
            vUSDCAmount = vK / vETHAmount;
        }
        
        // 计算剩余金额 (margin + pnl)
        // 由于 pnl 是负数且 |pnl| <= margin，所以 remaining >= 0
        int256 remaining = int256(position.margin) + pnl;
        
        // 删除被清算用户的头寸
        delete positions[_user];
        
        // 剩余资金归清算人所有（作为清算奖励）
        if (remaining > 0) {
            USDC.transfer(msg.sender, uint256(remaining));
        }
        
        emit PositionLiquidated(_user, msg.sender, pnl);
    }
}
