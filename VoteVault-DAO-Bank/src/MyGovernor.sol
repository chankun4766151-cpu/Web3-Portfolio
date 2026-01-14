// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

/**
 * @title MyGovernor
 * @dev DAO 治理合约，管理 Bank 合约的资金使用
 * 
 * 继承的合约说明：
 * 1. Governor: 核心治理逻辑
 * 2. GovernorSettings: 可配置的投票参数（延迟、期限、提案阈值）
 * 3. GovernorCountingSimple: 简单计票机制（赞成/反对/弃权）
 * 4. GovernorVotes: 使用 ERC20Votes 代币进行投票
 * 
 * 治理参数：
 * - votingDelay: 1 区块（提案创建后 1 个区块开始投票）
 * - votingPeriod: 50400 区块（约 7 天，假设 12 秒/区块）
 * - proposalThreshold: 0（任何人都可以创建提案）
 * 
 * 提案生命周期：
 * 1. Pending（待定）: 刚创建，等待 votingDelay
 * 2. Active（活跃）: 可以投票
 * 3. Defeated（失败）: 未达到法定人数或反对票多
 * 4. Succeeded（成功）: 达到法定人数且赞成票多
 * 5. Executed（已执行）: 提案已执行
 */
contract MyGovernor is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes {
    /**
     * @dev 构造函数
     * @param _token 投票代币合约地址（VotingToken）
     * 
     * 参数说明：
     * - votingDelay: 1 区块
     * - votingPeriod: 50400 区块（约 7 天）
     * - proposalThreshold: 0（任何人可创建提案）
     */
    constructor(IVotes _token)
        Governor("MyGovernor")
        GovernorSettings(
            1,      /* votingDelay: 提案创建后延迟 1 个区块开始投票 */
            50400,  /* votingPeriod: 投票期 50400 区块（约 7 天）*/
            0       /* proposalThreshold: 创建提案需要的最小投票权（0 = 任何人都可创建）*/
        )
        GovernorVotes(_token)
    {}

    /**
     * @dev 设置法定人数（Quorum）
     * @return 需要的最少投票数（总供应量的 4%）
     * 
     * 法定人数说明：
     * - 提案要通过，至少需要 4% 的代币参与投票
     * - 例如：总供应量 1,000,000，则需要至少 40,000 票
     */
    function quorum(uint256 timepoint)
        public
        view
        override
        returns (uint256)
    {
        // 计算指定时间点的总投票权
        uint256 totalSupply = token().getPastTotalSupply(timepoint);
        // 返回 4% 作为法定人数
        return (totalSupply * 4) / 100;
    }

    // 以下是必须的函数重写，用于解决多重继承冲突

    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}
