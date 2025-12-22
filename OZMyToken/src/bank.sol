// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    // 1. 使用地址类型：记录管理员（合约部署者）
    address public owner;

    // 2. 使用映射：记录每个地址的存款金额
    // key: 存款用户地址  value: 存款总额（单位：wei）
    mapping(address => uint) public balances;

    // 3. 使用数组：记录存款金额排名前 3 的用户地址
    // 固定长度数组，没填的位置为 address(0)
    address[3] public topUsers;

    // 构造函数：部署时设置管理员
    constructor() {
        owner = msg.sender;
    }

    // ========= 合约如何接收 ETH =========

    // // 方式一：直接向合约地址转账时，会自动调用 receive()
    // receive() external payable {
    //     _deposit(msg.sender, msg.value);
    // }

    // 方式二：显式调用 deposit() 存款（方便在 Remix 里测试）
    function deposit() public payable {
        _deposit(msg.sender, msg.value);
    }

    // 内部函数：处理存款逻辑，更新 balances 和前 3 名
    function _deposit(address user, uint amount) internal {
        require(amount > 0, "amount = 0");
        balances[user] += amount;   // 映射写入

        // 更新前 3 名数组
        _updateTop(user);
    }

    // ========= 仅管理员可以取款 =========

    // 只有 owner 可以调用 withdraw
    function withdraw(uint amount) public {
        require(msg.sender == owner, "not owner");
        require(amount <= address(this).balance, "insufficient");

        // 使用地址类型中的 payable：可以给地址转账
        payable(owner).transfer(amount);
    }

    // ========= 使用数组记录存款前 3 名 =========

    /**
     * 修复点：
     * - 旧逻辑是“插入式交换”，不会先移除 user 的旧位置，导致 Top3 可能出现重复地址
     * - 新逻辑：把 (topUsers + user) 组成候选池（最多4个），去重后按余额排序，取前3名
     */
    function _updateTop(address user) internal {
        // 1) 候选池：原 top3 + 本次更新的 user（最多4个）
        address[4] memory cands = [topUsers[0], topUsers[1], topUsers[2], user];

        // 2) 去重：出现重复的（后出现的）直接置 0
        for (uint i = 0; i < cands.length; i++) {
            if (cands[i] == address(0)) continue;
            for (uint j = i + 1; j < cands.length; j++) {
                if (cands[i] == cands[j]) {
                    cands[j] = address(0);
                }
            }
        }

        // 3) 排序：按 balances 从大到小（selection sort，最多4个，gas 很小）
        for (uint i = 0; i < cands.length; i++) {
            uint best = i;
            for (uint j = i + 1; j < cands.length; j++) {
                if (balances[cands[j]] > balances[cands[best]]) {
                    best = j;
                }
            }
            if (best != i) {
                address tmp = cands[i];
                cands[i] = cands[best];
                cands[best] = tmp;
            }
        }

        // 4) 写回 topUsers：取前3个非 0 的地址；不够就补 0
        uint k = 0;
        for (uint i = 0; i < cands.length && k < 3; i++) {
            if (cands[i] != address(0) && balances[cands[i]] > 0) {
                topUsers[k] = cands[i];
                k++;
            }
        }
        while (k < 3) {
            topUsers[k] = address(0);
            k++;
        }
    }

    // 辅助函数：查看前 3 名的余额
    function getTopBalances() public view returns (uint[3] memory) {
        uint[3] memory arr;
        for (uint i = 0; i < topUsers.length; i++) {
            arr[i] = balances[topUsers[i]];
        }
        return arr;
    }
}
