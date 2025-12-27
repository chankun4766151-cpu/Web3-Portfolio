// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ========== 基础 Bank 合约（在老师版本上稍作修改：关键函数加 virtual） ========== */
contract Bank {
    // 管理员地址
    address public owner;

    // 每个地址的存款余额
    mapping(address => uint) public balances;

    // 存款前 3 名的用户
    address[3] public topUsers;

    constructor() {
        owner = msg.sender;
    }

    // ------------ 对外存款函数（标记为 virtual，方便子合约 override） ------------
    function deposit() public payable virtual {
        _deposit(msg.sender, msg.value);
    }

    // 内部存款逻辑
    function _deposit(address user, uint amount) internal {
        require(amount > 0, "amount = 0");
        balances[user] += amount;
        _updateTop(user);
    }

    // ------------ 仅管理员可以取款（标记为 virtual，方便子合约 override（如果想）） ------------
    function withdraw(uint amount) public virtual {
        require(msg.sender == owner, "not owner");
        require(amount <= address(this).balance, "insufficient");
        payable(owner).transfer(amount);
    }

    // 简单更新前 3 名
    function _updateTop(address user) internal {
        uint bal = balances[user];

        address tempAddr = user;
        uint tempBal = bal;

        for (uint i = 0; i < topUsers.length; i++) {
            address curAddr = topUsers[i];
            uint curBal = balances[curAddr];

            if (tempBal > curBal) {
                topUsers[i] = tempAddr;
                tempAddr = curAddr;
                tempBal = curBal;
            }
        }
    }

    // 查看前 3 名的余额
    function getTopBalances() public view returns (uint[3] memory) {
        uint[3] memory arr;
        for (uint i = 0; i < topUsers.length; i++) {
            arr[i] = balances[topUsers[i]];
        }
        return arr;
    }
}

/* ========== 接口：Admin 只需要关心 BigBank/Bank 的 withdraw 函数 ========== */
interface IBigBank {
    function withdraw(uint amount) external;
}

/* ========== BigBank：继承自 Bank，增加“>0.001 ether 才能存款”和管理员转移 ========== */
contract BigBank is Bank {
    // 1️⃣ 限制存款金额必须 > 0.001 ether 的 modifier
    modifier onlyBigDeposit() {
        require(msg.value > 0.001 ether, "deposit must > 0.001 ether");
        _;
    }

    // 2️⃣ 重写 deposit，增加金额限制，并继续复用父合约存款逻辑
    function deposit() public payable override onlyBigDeposit {
        _deposit(msg.sender, msg.value);  // 调用 Bank 里的内部逻辑
    }

    // 3️⃣ 把管理员（owner）转移给 Admin 合约
    function transferAdmin(address newAdmin) public {
        require(msg.sender == owner, "only owner can transfer admin");
        require(newAdmin != address(0), "invalid admin");
        owner = newAdmin;
    }
}

/* ========== Admin 合约：通过接口调用 BigBank 的 withdraw() ========== */
contract Admin {
    // 用接口类型保存 BigBank 地址（解耦）
    IBigBank public bigBank;

    // 部署 Admin 时，把 BigBank 地址传进来
    constructor(address bigBankAddr) {
        bigBank = IBigBank(bigBankAddr);
    }

    // Admin 合约来调用 BigBank 的 withdraw()
    function callWithdraw(uint amount) public {
        // 这里可以加自己的权限控制，例如只允许部署者调用
        bigBank.withdraw(amount);
    }
}
