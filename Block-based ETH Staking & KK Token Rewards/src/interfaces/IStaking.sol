// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStaking - 质押合约接口
 * @notice 定义质押池的核心功能
 */
interface IStaking {
    /**
     * @dev 质押 ETH 到合约
     * @notice 用户发送 ETH 调用此函数进行质押
     */
    function stake() payable external;

    /**
     * @dev 赎回质押的 ETH
     * @param amount 赎回数量（单位：wei）
     * @notice 会自动结算之前的奖励
     */
    function unstake(uint256 amount) external;

    /**
     * @dev 领取 KK Token 收益
     * @notice 将累积的奖励发送给调用者
     */
    function claim() external;

    /**
     * @dev 获取质押的 ETH 数量
     * @param account 质押账户地址
     * @return 该账户质押的 ETH 数量（单位：wei）
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev 获取待领取的 KK Token 收益
     * @param account 质押账户地址
     * @return 待领取的 KK Token 收益数量
     */
    function earned(address account) external view returns (uint256);
}
