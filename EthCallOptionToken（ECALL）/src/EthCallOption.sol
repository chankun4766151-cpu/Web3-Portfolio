// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title EthCallOption
 * @notice ETH 看涨期权 Token 合约
 * @dev 实现了一个 ERC20 期权 Token，允许项目方发行期权，用户在到期日行权
 */
contract EthCallOption is ERC20 {
    // ============ 状态变量 ============
    
    /// @notice 项目方地址（合约所有者）
    address public immutable owner;
    
    /// @notice 行权价格（单位：USDT per ETH，18 decimals）
    /// @dev 例如：2000 * 10^18 表示 1 ETH = 2000 USDT
    uint256 public immutable strikePrice;
    
    /// @notice 行权日期（Unix 时间戳）
    uint256 public immutable expiryDate;
    
    /// @notice 支付代币（USDT）
    IERC20 public immutable paymentToken;
    
    /// @notice 是否已过期并销毁
    bool public isExpired;

    // ============ 事件 ============
    
    /// @notice 发行期权事件
    event OptionIssued(address indexed issuer, uint256 ethAmount, uint256 optionTokenAmount);
    
    /// @notice 行权事件
    event OptionExercised(address indexed holder, uint256 optionAmount, uint256 ethReceived, uint256 usdtPaid);
    
    /// @notice 过期销毁事件
    event OptionExpired(address indexed owner, uint256 ethRedeemed);

    // ============ 修饰符 ============
    
    /// @notice 只有项目方可以调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /// @notice 只能在行权日当天行权
    modifier onlyOnExpiryDate() {
        require(block.timestamp >= expiryDate && block.timestamp < expiryDate + 1 days, 
                "Can only exercise on expiry date");
        _;
    }
    
    /// @notice 确保未过期销毁
    modifier notExpired() {
        require(!isExpired, "Option has been expired and redeemed");
        _;
    }

    // ============ 构造函数 ============
    
    /**
     * @notice 构造函数 - 初始化期权参数
     * @param _strikePrice 行权价格（USDT per ETH）
     * @param _expiryDate 行权日期（Unix 时间戳）
     * @param _paymentToken 支付代币地址（USDT）
     */
    constructor(
        uint256 _strikePrice,
        uint256 _expiryDate,
        address _paymentToken
    ) ERC20("ETH Call Option Token", "ECALL") {
        require(_strikePrice > 0, "Strike price must be greater than 0");
        require(_expiryDate > block.timestamp, "Expiry date must be in the future");
        require(_paymentToken != address(0), "Invalid payment token address");
        
        owner = msg.sender;
        strikePrice = _strikePrice;
        expiryDate = _expiryDate;
        paymentToken = IERC20(_paymentToken);
    }

    // ============ 核心功能 ============
    
    /**
     * @notice 发行期权（项目方角色）
     * @dev 项目方存入 ETH，按 1:1 比例铸造期权 Token
     * - 项目方发送 ETH 到合约
     * - 合约铸造等量的期权 Token 给项目方
     * - 项目方可以将期权 Token 出售给用户
     */
    function issue() external payable onlyOwner notExpired {
        require(msg.value > 0, "Must send ETH to issue options");
        
        // 铸造期权 Token（1 ETH = 1 期权 Token）
        uint256 optionTokenAmount = msg.value;
        _mint(msg.sender, optionTokenAmount);
        
        emit OptionIssued(msg.sender, msg.value, optionTokenAmount);
    }
    
    /**
     * @notice 行权（用户角色）
     * @dev 用户在行权日当天，销毁期权 Token，支付行权价格，获取 ETH
     * @param amount 要行权的期权 Token 数量
     * 
     * 行权流程：
     * 1. 检查是否在行权日当天
     * 2. 检查用户的期权 Token 余额
     * 3. 计算需要支付的 USDT 金额 = amount * strikePrice / 1e18
     * 4. 从用户账户转入 USDT 到合约
     * 5. 销毁用户的期权 Token
     * 6. 转移等量的 ETH 给用户
     */
    function exercise(uint256 amount) external onlyOnExpiryDate notExpired {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient option token balance");
        
        // 计算需要支付的 USDT 金额
        // amount 是期权 Token 数量（对应 ETH 数量，18 decimals）
        // strikePrice 是每 ETH 的 USDT 价格（18 decimals）
        // 所以总支付 = (amount * strikePrice) / 1e18
        uint256 usdtAmount = (amount * strikePrice) / 1e18;
        
        // 转入 USDT
        require(
            paymentToken.transferFrom(msg.sender, address(this), usdtAmount),
            "USDT transfer failed"
        );
        
        // 销毁期权 Token
        _burn(msg.sender, amount);
        
        // 转移 ETH 给用户
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
        
        emit OptionExercised(msg.sender, amount, amount, usdtAmount);
    }
    
    /**
     * @notice 过期销毁（项目方角色）
     * @dev 在行权日之后，项目方可以销毁所有期权，赎回剩余的 ETH
     * 
     * 过期销毁流程：
     * 1. 检查是否已过行权日
     * 2. 标记合约为已过期
     * 3. 将合约中所有 ETH 返还给项目方
     * 4. 将收到的 USDT 也转给项目方
     */
    function expireAndRedeem() external onlyOwner notExpired {
        require(block.timestamp >= expiryDate + 1 days, 
                "Can only expire after expiry date");
        
        // 标记为已过期
        isExpired = true;
        
        // 获取合约中的 ETH 和 USDT 余额
        uint256 ethBalance = address(this).balance;
        uint256 usdtBalance = paymentToken.balanceOf(address(this));
        
        // 转移 ETH 给项目方
        if (ethBalance > 0) {
            (bool success, ) = owner.call{value: ethBalance}("");
            require(success, "ETH transfer failed");
        }
        
        // 转移 USDT 给项目方
        if (usdtBalance > 0) {
            require(
                paymentToken.transfer(owner, usdtBalance),
                "USDT transfer failed"
            );
        }
        
        emit OptionExpired(owner, ethBalance);
    }
    
    // ============ 查询功能 ============
    
    /**
     * @notice 获取合约中的 ETH 余额
     */
    function getEthBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice 获取合约中的 USDT 余额
     */
    function getUsdtBalance() external view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }
    
    /**
     * @notice 计算行权所需的 USDT 金额
     * @param optionAmount 期权 Token 数量
     */
    function calculateExerciseCost(uint256 optionAmount) external view returns (uint256) {
        return (optionAmount * strikePrice) / 1e18;
    }
}
