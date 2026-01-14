// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title VotingToken
 * @dev 支持投票功能的 ERC20 代币
 * 
 * 核心功能：
 * 1. 标准 ERC20 代币功能
 * 2. ERC20Permit: 支持链下签名授权（gasless approval）
 * 3. ERC20Votes: 支持投票权重跟踪
 * 
 * 投票机制说明：
 * - 每个代币 = 1 票投票权
 * - 用户必须先 delegate（委托）才能激活投票权
 * - 可以委托给自己：delegate(自己的地址)
 * - 也可以委托给他人：delegate(他人地址)
 * - 使用检查点（checkpoint）记录历史投票权，防止双重投票
 */
contract VotingToken is ERC20, ERC20Permit, ERC20Votes {
    /**
     * @dev 构造函数
     * @notice 初始铸造 1,000,000 代币给部署者
     */
    constructor() 
        ERC20("VoteVault Token", "VVT") 
        ERC20Permit("VoteVault Token") 
    {
        // 铸造 1,000,000 代币（18 位小数）
        _mint(msg.sender, 1_000_000 * 10**decimals());
    }

    // 以下函数是必须的重写，用于解决多重继承冲突

    /**
     * @dev 内部转账后的钩子函数
     * @notice 在代币转账后更新投票权重
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    /**
     * @dev 返回当前随机数
     * @notice 用于 ERC20Permit 签名验证
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
