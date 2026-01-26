// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockToken
 * @dev 测试用ERC20代币
 */
contract MockToken is ERC20 {
    uint8 private _decimals;
    
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/**
 * @title MockYieldProtocol
 * @dev 模拟收益协议 (如 Aave, Compound)
 */
contract MockYieldProtocol {
    using SafeERC20 for IERC20;
    
    string public name;
    IERC20 public depositToken;
    uint256 public apy; // APY in basis points (10000 = 100%)
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public depositTime;
    
    constructor(string memory _name, address _depositToken, uint256 _apy) {
        name = _name;
        depositToken = IERC20(_depositToken);
        apy = _apy;
    }
    
    function deposit(uint256 amount) external {
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // 先结算之前的利息
        uint256 interest = _calculateInterest(msg.sender);
        deposits[msg.sender] += amount + interest;
        depositTime[msg.sender] = block.timestamp;
    }
    
    function withdraw(uint256 amount) external {
        uint256 interest = _calculateInterest(msg.sender);
        uint256 totalBalance = deposits[msg.sender] + interest;
        
        require(amount <= totalBalance, "Insufficient balance");
        
        deposits[msg.sender] = totalBalance - amount;
        depositTime[msg.sender] = block.timestamp;
        
        depositToken.safeTransfer(msg.sender, amount);
    }
    
    function getAPY() external view returns (uint256) {
        return apy;
    }
    
    function setAPY(uint256 _apy) external {
        apy = _apy;
    }
    
    function getBalance(address user) external view returns (uint256) {
        return deposits[user] + _calculateInterest(user);
    }
    
    function _calculateInterest(address user) internal view returns (uint256) {
        if (deposits[user] == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - depositTime[user];
        // 简化计算：年利息 = 本金 * APY / 10000
        // 实际利息 = 年利息 * 经过时间 / 365天
        uint256 yearlyInterest = (deposits[user] * apy) / 10000;
        return (yearlyInterest * timeElapsed) / 365 days;
    }
}

/**
 * @title MockBridge
 * @dev 模拟跨链桥
 */
contract MockBridge {
    string public name;
    uint256 public baseFee; // 基础费用 (wei)
    uint256 public feeRate; // 费率 (basis points)
    uint256 public estimatedTime; // 预估时间 (秒)
    
    event BridgeInitiated(
        address indexed sender,
        uint256 dstChainId,
        address token,
        uint256 amount,
        address recipient
    );
    
    constructor(
        string memory _name,
        uint256 _baseFee,
        uint256 _feeRate,
        uint256 _estimatedTime
    ) {
        name = _name;
        baseFee = _baseFee;
        feeRate = _feeRate;
        estimatedTime = _estimatedTime;
    }
    
    function getFee(
        uint256, // srcChainId
        uint256, // dstChainId
        address, // token
        uint256 amount
    ) external view returns (uint256 fee, uint256 time) {
        fee = baseFee + (amount * feeRate) / 10000;
        time = estimatedTime;
    }
    
    function bridge(
        uint256 dstChainId,
        address token,
        uint256 amount,
        address recipient
    ) external payable {
        // 模拟接收代币 (实际桥会锁定代币)
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        emit BridgeInitiated(msg.sender, dstChainId, token, amount, recipient);
    }
    
    function setFees(uint256 _baseFee, uint256 _feeRate) external {
        baseFee = _baseFee;
        feeRate = _feeRate;
    }
    
    function setEstimatedTime(uint256 _time) external {
        estimatedTime = _time;
    }
}

/**
 * @title MockDEXRouter
 * @dev 模拟DEX路由器
 */
contract MockDEXRouter {
    string public name;
    
    // tokenA => tokenB => 兑换率 (tokenB per tokenA, 18 decimals)
    mapping(address => mapping(address => uint256)) public exchangeRates;
    
    constructor(string memory _name) {
        name = _name;
    }
    
    function setExchangeRate(
        address tokenA,
        address tokenB,
        uint256 rate
    ) external {
        exchangeRates[tokenA][tokenB] = rate;
        // 设置反向汇率
        if (rate > 0) {
            exchangeRates[tokenB][tokenA] = (1e36) / rate;
        }
    }
    
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut) {
        uint256 rate = exchangeRates[tokenIn][tokenOut];
        require(rate > 0, "No exchange rate set");
        
        amountOut = (amountIn * rate) / 1e18;
    }
    
    // 模拟swap功能
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external returns (uint256 amountOut) {
        amountOut = (amountIn * exchangeRates[tokenIn][tokenOut]) / 1e18;
        require(amountOut >= minAmountOut, "Insufficient output");
        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // 在真实场景中，DEX会从流动性池中转出代币
        // 这里假设DEX有足够的代币
        IERC20(tokenOut).transfer(recipient, amountOut);
        
        return amountOut;
    }
}
