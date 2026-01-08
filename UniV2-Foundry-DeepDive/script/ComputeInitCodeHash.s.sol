// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/UniswapV2Factory.sol";
import "../src/core/UniswapV2Pair.sol";

/**
 * @title ComputeInitCodeHash
 * @notice 计算 UniswapV2Pair 的 init_code_hash
 * @dev 运行此脚本获取正确的 init_code_hash，用于 UniswapV2Library.pairFor()
 * 
 * 使用方法：
 * forge script script/ComputeInitCodeHash.s.sol
 */
contract ComputeInitCodeHash is Script {
    function run() external view {
        // 获取 UniswapV2Pair 的创建字节码
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        
        // 计算 keccak256 哈希
        bytes32 hash = keccak256(bytecode);
        
        console.log("===========================================");
        console.log("UniswapV2Pair init_code_hash:");
        console.logBytes32(hash);
        console.log("===========================================");
        console.log("");
        console.log("Copy this hash to UniswapV2Library.pairFor() if you're using a fixed hash.");
        console.log("Our implementation uses dynamic calculation with type(UniswapV2Pair).creationCode");
    }
}
