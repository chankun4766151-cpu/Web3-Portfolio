// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title TestERC20
 * @dev 测试用的 ERC20 代币，支持任何人铸造
 */
contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // 给部署者铸造初始供应量
        _mint(msg.sender, 1000000 * 10**decimals());
    }
    
    /**
     * @dev 铸造代币 (测试用)
     * @param to 接收者地址
     * @param amount 数量
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
