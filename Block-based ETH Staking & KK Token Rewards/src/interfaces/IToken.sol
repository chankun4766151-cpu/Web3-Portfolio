// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IToken - KK Token 接口
 * @notice 继承 IERC20 并添加 mint 功能
 * @dev 只有授权的 Staking 合约可以调用 mint
 */
interface IToken is IERC20 {
    /**
     * @dev 铸造新的 KK Token
     * @param to 接收代币的地址
     * @param amount 铸造数量
     */
    function mint(address to, uint256 amount) external;
}
