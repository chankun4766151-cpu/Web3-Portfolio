// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenBank {
    using SafeERC20 for IERC20;

    mapping(address => mapping(address => uint256)) public balances;
    address public tokenAddress;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256 amount) public {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        balances[tokenAddress][msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev 支持 EIP-2612 Permit 的存款函数。
     * @param amount 存款金额
     * @param deadline 签名有效期
     * @param v 签名参数 v
     * @param r 签名参数 r
     * @param s 签名参数 s
     */
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // 1. 调用 token 的 permit 函数，利用签名进行授权
        // 这样 msg.sender 就不需要提前调用 approve 了
        IERC20Permit(tokenAddress).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // 2. 调用已有的 deposit 函数完成实际的转账和记账
        deposit(amount);
    }

    function withdraw(uint256 amount) public {
        require(balances[tokenAddress][msg.sender] >= amount, "Insufficient balance");
        balances[tokenAddress][msg.sender] -= amount;
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }
}
