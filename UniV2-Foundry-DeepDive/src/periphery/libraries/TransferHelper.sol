// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TransferHelper 库
 * @notice 安全的代币转账工具库
 * @dev 提供安全的 ERC20 操作，兼容不标准的代币
 * 
 * 为什么需要这个库？
 * 1. 有些代币（如 USDT）的 transfer/approve 不返回 bool
 * 2. 有些代币返回 false 而不是 revert
 * 3. 这个库统一处理这些情况
 */
library TransferHelper {
    /**
     * @notice 安全授权
     * @dev 使用低级 call 调用 approve，检查返回值
     * @param token 代币地址
     * @param to 被授权地址
     * @param value 授权数量
     */
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    /**
     * @notice 安全转账
     * @dev 使用低级 call 调用 transfer，检查返回值
     * @param token 代币地址
     * @param to 接收地址
     * @param value 转账数量
     */
    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    /**
     * @notice 安全授权转账
     * @dev 使用低级 call 调用 transferFrom，检查返回值
     * @param token 代币地址
     * @param from 发送地址
     * @param to 接收地址
     * @param value 转账数量
     */
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    /**
     * @notice 安全转账 ETH
     * @dev 使用 call 发送 ETH，检查成功状态
     * @param to 接收地址
     * @param value 转账数量
     */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}
