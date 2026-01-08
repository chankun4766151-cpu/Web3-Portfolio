// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title WETH9
 * @notice Wrapped Ether 合约
 * @dev 将 ETH 包装为 ERC20 代币，实现 1:1 锚定
 * 
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                            为什么需要 WETH？                                ║
 * ╠═══════════════════════════════════════════════════════════════════════════╣
 * ║  问题：                                                                     ║
 * ║  - ETH 是以太坊的原生货币，不是 ERC20 代币                                    ║
 * ║  - Uniswap 交易对只能处理 ERC20 代币                                         ║
 * ║  - ETH 和 ERC20 有不同的转账接口                                             ║
 * ║                                                                            ║
 * ║  解决方案：                                                                  ║
 * ║  - WETH 是一个 ERC20 代币，与 ETH 1:1 锚定                                   ║
 * ║  - deposit(): 存入 ETH，获得等量 WETH                                        ║
 * ║  - withdraw(): 取出 WETH，换回等量 ETH                                       ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */
contract WETH9 {
    // ==================== 状态变量 ====================
    
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    /// @notice 地址 => 余额 映射
    mapping(address => uint256) public balanceOf;
    
    /// @notice 授权额度映射
    mapping(address => mapping(address => uint256)) public allowance;

    // ==================== 事件 ====================
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    // ==================== 接收 ETH ====================
    
    /**
     * @notice 接收 ETH 时自动存入
     * @dev 当直接向合约发送 ETH 时触发
     */
    receive() external payable {
        deposit();
    }

    /**
     * @notice 回退函数
     */
    fallback() external payable {
        deposit();
    }

    // ==================== 核心函数 ====================
    
    /**
     * @notice 存入 ETH，获得等量 WETH
     * @dev 接收 msg.value 数量的 ETH，铸造等量 WETH 给调用者
     * 
     * 示例：
     * - 调用者发送 1 ETH
     * - 调用者获得 1 WETH
     * - 合约持有 1 ETH
     */
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @notice 取出 WETH，换回等量 ETH
     * @dev 销毁 WETH，返还等量 ETH 给调用者
     * 
     * 示例：
     * - 调用者有 1 WETH
     * - 调用 withdraw(1 ether)
     * - 调用者的 WETH 减少 1
     * - 调用者获得 1 ETH
     * 
     * @param wad 取出数量（单位：wei）
     */
    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad, "WETH: insufficient balance");
        balanceOf[msg.sender] -= wad;
        
        // 发送 ETH 给调用者
        (bool success, ) = msg.sender.call{value: wad}("");
        require(success, "WETH: ETH transfer failed");
        
        emit Withdrawal(msg.sender, wad);
    }

    // ==================== ERC20 函数 ====================
    
    /**
     * @notice 返回 WETH 总供应量
     * @dev 等于合约持有的 ETH 数量
     */
    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice 授权
     * @param guy 被授权地址
     * @param wad 授权数量
     */
    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    /**
     * @notice 转账
     * @param dst 接收地址
     * @param wad 转账数量
     */
    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    /**
     * @notice 授权转账
     * @param src 发送地址
     * @param dst 接收地址
     * @param wad 转账数量
     */
    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(balanceOf[src] >= wad, "WETH: insufficient balance");

        // 如果不是自己转自己，且授权额度不是无限大，则扣减授权额度
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "WETH: insufficient allowance");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);
        return true;
    }
}
