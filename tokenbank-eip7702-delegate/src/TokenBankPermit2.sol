// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IPermit2.sol";

/**
 * @title TokenBankPermit2
 * @dev 支持 Permit2 签名存款的代币银行
 *
 * 功能特性：
 * - 传统存款/取款（需要先 approve）
 * - depositWithPermit2：使用 Permit2 签名进行无 gas 授权的存款
 * - ReentrancyGuard：防止重入攻击
 * 
 * 使用流程：
 * 1. 用户一次性授权 Permit2 合约使用自己的代币（approve Permit2）
 * 2. 想要存款时，用户签名授权（离线操作，不花 gas）
 * 3. 调用 depositWithPermit2，传入签名数据
 * 4. 合约验证签名并完成存款
 */
contract TokenBankPermit2 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ========== 自定义错误（节省 gas）==========
    error ZeroAmount();              // 金额为 0
    error ZeroAddress();             // 地址为 0
    error InsufficientBalance();     // 余额不足
    error InvalidToken();            // 无效的代币地址

    // ========== 状态变量 ==========
    IERC20 public immutable token;      // 银行接受的代币
    IPermit2 public immutable permit2;  // Permit2 合约地址
    
    // 用户余额映射：用户地址 => 存款金额
    mapping(address => uint256) public balances;

    // ========== 事件 ==========
    event Deposit(address indexed user, uint256 amount);
    event Permit2Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev 构造函数
     * @param _token 接受的 ERC20 代币地址
     * @param _permit2 Permit2 合约地址
     * 
     * 说明：
     * - _token: 你的 MyToken 合约地址
     * - _permit2: Uniswap 官方部署的 Permit2 合约地址
     *   Sepolia: 0x000000000022D473030F116dDEE9F6B43aC78BA3
     */
    constructor(address _token, address _permit2) {
        if (_token == address(0) || _permit2 == address(0)) revert ZeroAddress();
        token = IERC20(_token);
        permit2 = IPermit2(_permit2);
    }

    /**
     * @dev 传统存款方式（需要先 approve）
     * @param amount 存款金额
     * 
     * 使用步骤：
     * 1. 先调用 token.approve(TokenBankPermit2地址, amount)
     * 2. 再调用 deposit(amount)
     * 
     * 缺点：需要两次交易，花费两次 gas
     */
    function deposit(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        // 从用户钱包转代币到本合约
        token.safeTransferFrom(msg.sender, address(this), amount);
        
        // 更新用户余额
        balances[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev 使用 Permit2 签名进行存款 ⭐ 核心功能 ⭐
     * @param permitTransfer 用户签名的授权数据
     * @param owner 代币所有者（签名者）
     * @param signature EIP-712 签名
     * 
     * 工作原理：
     * 1. 用户在链下对存款操作进行签名（不花 gas）
     * 2. 调用本函数，传入签名数据
     * 3. 合约调用 Permit2.permitTransferFrom 验证签名
     * 4. Permit2 验证通过后，从用户钱包转代币到本合约
     * 5. 更新用户在银行的余额
     * 
     * 优势：
     * - 用户只需一次性授权 Permit2（一劳永逸）
     * - 之后的每次存款只需签名，不需要额外的 approve 交易
     * - 节省 gas 费用和交易时间
     */
    function depositWithPermit2(
        IPermit2.PermitTransferFrom calldata permitTransfer,
        address owner,
        bytes calldata signature
    ) external nonReentrant {
        // 验证：金额不能为 0
        if (permitTransfer.permitted.amount == 0) revert ZeroAmount();
        
        // 验证：签名授权的代币必须是本银行接受的代币
        if (permitTransfer.permitted.token != address(token)) revert InvalidToken();

        // 构造转账详情：代币转到本合约，金额为用户签名授权的金额
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),                          // 接收方：本合约
            requestedAmount: permitTransfer.permitted.amount  // 转账金额
        });

        // 调用 Permit2 合约进行签名验证和转账
        // Permit2 会：
        // 1. 验证 signature 是否由 owner 签名
        // 2. 验证签名是否过期（deadline）
        // 3. 验证 nonce 防止重放攻击
        // 4. 从 owner 转账到 transferDetails.to（本合约）
        permit2.permitTransferFrom(
            permitTransfer,
            transferDetails,
            owner,
            signature
        );

        // 更新用户余额（注意：是 owner 的余额，不是 msg.sender）
        // 因为代币的实际所有者是 owner（签名者）
        balances[owner] += permitTransfer.permitted.amount;

        emit Permit2Deposit(owner, permitTransfer.permitted.amount);
    }

    /**
     * @dev 取款
     * @param amount 取款金额
     * 
     * 说明：
     * - 任何人都可以取出自己在银行的存款
     * - 采用"先扣账，再转账"模式，防止重入攻击
     */
    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        // 先减少余额（防止重入攻击）
        balances[msg.sender] -= amount;
        
        // 再转账
        token.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev 查询用户余额
     * @param account 要查询的地址
     * @return 该地址在银行的存款余额
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev 查询银行持有的代币总量
     * @return 银行合约持有的代币总数
     */
    function bankTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
