# EIP-7702 TokenBank 作业任务清单

## 📌 作业要求
1. 使用 MetaMask 官方 EIP-7702 Delegator 合约 (`0x63c0c19a282a1B52b07dD5a65b58948A07DAE32B`)
2. 修改 TokenBank 前端，实现 EOA 授权并在一个交易中完成授权和存款
3. 提交 GitHub 代码和测试网交易链接

---

## ✅ 已完成的任务

- [x] 添加 Delegator 合约配置 <!-- id: 0 -->
    - [x] 更新 `frontend/constants/addresses.ts`
    - [x] 创建 `frontend/constants/Delegator.abi.ts`

- [x] 实现 EIP-7702 核心功能 <!-- id: 1 -->
    - [x] 添加私钥账户支持（绕过 JSON-RPC 限制）
    - [x] 实现 `signAuthorization` 签名逻辑
    - [x] 构建批量执行（Approve + Deposit）
    - [x] 发送 EIP-7702 授权交易

- [x] 更新前端 UI <!-- id: 2 -->
    - [x] 添加私钥输入框（带显示/隐藏功能）
    - [x] 创建 "⚡ EIP-7702 极速存款" 区域
    - [x] 优化用户体验和错误提示

---

## 🎯 待完成的任务

- [ ] 测试功能 <!-- id: 3 -->
    - [ ] 准备测试账户私钥
    - [ ] 刷新页面并输入私钥
    - [ ] 执行 EIP-7702 授权并存款
    - [ ] 复制交易哈希
    - [ ] 在区块浏览器验证交易

- [ ] 提交作业 <!-- id: 4 -->
    - [ ] 提交代码到 GitHub
    - [ ] 准备作业提交材料（GitHub 链接 + 交易哈希）
