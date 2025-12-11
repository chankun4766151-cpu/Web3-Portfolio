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

    // // 方式二：显式调用 deposit() 存款（方便在 Remix 里测试）
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

    // 简单插入排序：把 user 按余额大小插入 topUsers[0..2]
    function _updateTop(address user) internal {
        uint bal = balances[user];

        address tempAddr = user;
        uint tempBal = bal;

        // 遍历 0,1,2 三个位置
        for (uint i = 0; i < topUsers.length; i++) {
            address curAddr = topUsers[i];
            uint curBal = balances[curAddr];

            // 如果当前用户余额更大，就把他插到这个位置
            if (tempBal > curBal) {
                // 交换：temp 放到后面，当前位置放新的
                topUsers[i] = tempAddr;

                tempAddr = curAddr;
                tempBal = curBal;
            }
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
