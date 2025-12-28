// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {
        // 铸造 1,000,000 个代币给部署者
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
    
    // 允许任何人铸造代币（仅用于测试）
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
