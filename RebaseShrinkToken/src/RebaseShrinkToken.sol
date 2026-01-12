// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RebaseShrinkToken
 * @dev 一个通缩型 Rebase ERC20 代币
 * 
 * 核心原理：
 * - 不直接存储用户余额，而是存储"份额 (shares)"
 * - 通过 rebase 机制调整总供应量，从而改变每个份额对应的实际代币数量
 * - 每次 rebase，总供应量减少 1%（模拟年度通缩）
 * 
 * 余额计算公式：
 * balance = shares × (totalSupply / totalShares)
 */
contract RebaseShrinkToken is IERC20, Ownable {
    string public name = "Rebase Shrink Token";
    string public symbol = "RST";
    uint8 public decimals = 18;
    
    // 初始供应量：1 亿代币
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    
    // 当前总供应量（随 rebase 变化）
    uint256 private _totalSupply;
    
    // 份额相关
    mapping(address => uint256) private _shares;      // 用户份额
    uint256 private _totalShares;                      // 总份额
    
    // 授权额度
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // rebase 计数（记录已经过了多少年）
    uint256 public rebaseCount;
    
    // 事件
    event Rebase(uint256 indexed epoch, uint256 totalSupply);

    constructor() Ownable(msg.sender) {
        // 初始化：总供应量和总份额都设为初始值
        _totalSupply = INITIAL_SUPPLY;
        _totalShares = INITIAL_SUPPLY;
        
        // 将所有份额分配给部署者
        _shares[msg.sender] = INITIAL_SUPPLY;
        
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev 获取当前总供应量
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev 获取用户余额（核心：通过份额计算实际余额）
     * 
     * 计算逻辑：
     * balance = userShares × (totalSupply / totalShares)
     * 
     * 这就是 rebase 的魔法所在！
     * - 当 totalSupply 减少时，每个 share 对应的 balance 也会减少
     * - 用户无需任何操作，余额自动按比例调整
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_totalShares == 0) return 0;
        return _shares[account] * _totalSupply / _totalShares;
    }

    /**
     * @dev 获取用户的原始份额
     */
    function sharesOf(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev 获取总份额
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev 执行 rebase（通缩操作）
     * 
     * 每次调用将总供应量减少 1%
     * 这代表"一年过去了"
     * 
     * 只有合约 owner 可以调用（实际项目中可能由时间锁或自动化机制触发）
     */
    function rebase() external onlyOwner {
        // 总供应量减少 1%：newSupply = oldSupply × 99 / 100
        _totalSupply = _totalSupply * 99 / 100;
        
        rebaseCount++;
        
        emit Rebase(rebaseCount, _totalSupply);
    }

    /**
     * @dev 转账函数
     * 
     * 转账逻辑：
     * 1. 将代币金额转换为份额
     * 2. 转移份额
     * 
     * 这确保了无论当前处于什么 rebase 状态，转账都是正确的
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev 内部转账函数
     * 
     * 关键点：将代币金额转换为等价的份额进行转移
     * sharesToTransfer = amount × totalShares / totalSupply
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        
        // 将代币金额转换为份额
        uint256 sharesToTransfer = amount * _totalShares / _totalSupply;
        
        require(_shares[from] >= sharesToTransfer, "Insufficient balance");
        
        _shares[from] -= sharesToTransfer;
        _shares[to] += sharesToTransfer;
        
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _allowances[owner][spender] = currentAllowance - amount;
            }
        }
    }
}
