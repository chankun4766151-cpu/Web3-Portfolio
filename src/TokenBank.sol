// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev 你 BaseERC20 里用到的最小 ERC20 接口
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @dev 你的 Token.sol 里的回调接口：ITokenReceiver(_to).tokensReceived(...)
 * ⚠️ 签名必须和 Token.sol 完全一致
 */
interface ITokenReceiver {
    function tokensReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external;
}

/**
 * @title TokenBank
 * @notice 普通版 Bank：需要先 approve，再 deposit；withdraw 取回
 */
contract TokenBank {
    IERC20 public immutable token;

    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "TokenBank: token is zero address");
        token = IERC20(_token);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "TokenBank: amount must be > 0");

        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "TokenBank: transferFrom failed");

        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "TokenBank: amount must be > 0");
        require(balances[msg.sender] >= amount, "TokenBank: insufficient balance");

        // 先扣账再转账（更安全）
        balances[msg.sender] -= amount;

        bool ok = token.transfer(msg.sender, amount);
        require(ok, "TokenBank: transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function bankTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}

/**
 * @title TokenBankV2
 * @notice 支持 BaseERC20.transferWithCallback 的自动入金
 *
 * 用法：
 * 1) 部署 BaseERC20，拿到 token 地址
 * 2) 部署 TokenBankV2(token地址)
 * 3) 用户调用 BaseERC20.transferWithCallback(TokenBankV2地址, amount, data)
 *    -> Token 会回调 tokensReceived -> Bank 记账
 */
contract TokenBankV2 is TokenBank, ITokenReceiver {
    event DepositByCallback(address indexed operator, address indexed from, uint256 amount, bytes data);

    constructor(address _token) TokenBank(_token) {}

    /**
     * @dev 由 Token 合约回调触发的入金记账
     * ⚠️ 必须限制 msg.sender == token，否则任何人都能伪造入金
     */
    function tokensReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external override {
        require(msg.sender == address(token), "TokenBankV2: only bound token can callback");
        require(value > 0, "TokenBankV2: value must be > 0");

        // 这里的 from 是“实际付款人/存款人”
        balances[from] += value;

        emit DepositByCallback(operator, from, value, data);
    }
}
