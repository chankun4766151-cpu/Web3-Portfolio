// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title MyToken
 * @dev 继承自 ERC20 和 ERC20Permit。
 * ERC20Permit 实现了 EIP-2612 标准，允许通过离线签名（permit）来授权额度，
 * 从而在一次交易中完成授权和转账（如存款），提升用户体验并节省 Gas。
 */
contract MyToken is ERC20, ERC20Permit {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        // 初始铸造 1,000,000 代币给部署者
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
