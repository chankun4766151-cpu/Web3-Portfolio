// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SimpleUniswapV2.sol";

/**
 * @title FlashSwapArbitrage
 * @dev Implements flash swap arbitrage between two Uniswap V2 pools with price differences
 * 
 * Strategy:
 * 1. Borrow TokenB from PoolA via flash swap (no upfront capital)
 * 2. Swap borrowed TokenB to TokenA on PoolB (higher price for TokenB)
 * 3. Repay PoolA with TokenA (plus 0.3% fee)
 * 4. Keep the profit in TokenA
 */
contract FlashSwapArbitrage is IUniswapV2Callee {
    address public owner;
    
    // Track profit for transparency
    uint256 public totalProfitTokenA;
    uint256 public totalProfitTokenB;
    
    event ArbitrageExecuted(
        address indexed poolA,
        address indexed poolB,
        uint256 borrowedAmount,
        uint256 profit,
        address profitToken
    );
    
    event ArbitrageStarted(
        address indexed poolA,
        address tokenBorrowed,
        uint256 amountBorrowed
    );

    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Execute arbitrage between two pools
     * @param poolA Pool to borrow from (via flash swap)
     * @param poolB Pool to swap on
     * @param borrowToken Token to borrow from poolA (should be token with higher price in poolB)
     * @param amountToBorrow Amount to borrow via flash swap
     */
    function executeArbitrage(
        address poolA,
        address poolB,
        address borrowToken,
        uint256 amountToBorrow
    ) external {
        require(msg.sender == owner, "Only owner");
        
        SimplePair pair = SimplePair(poolA);
        address token0 = pair.token0();
        address token1 = pair.token1();
        
        // Determine which token we're borrowing
        uint256 amount0Out = borrowToken == token0 ? amountToBorrow : 0;
        uint256 amount1Out = borrowToken == token1 ? amountToBorrow : 0;
        
        // Encode poolB address in data for the callback
        bytes memory data = abi.encode(poolB, borrowToken);
        
        emit ArbitrageStarted(poolA, borrowToken, amountToBorrow);
        
        // Initiate flash swap - this will trigger uniswapV2Call
        pair.swap(amount0Out, amount1Out, address(this), data);
    }
    
    /**
     * @dev Uniswap V2 callback - called during flash swap
     * This is where the arbitrage logic happens
     * @param sender The address that initiated the flash swap (should be this contract)
     * @param amount0 Amount of token0 received
     * @param amount1 Amount of token1 received
     * @param data Encoded data containing poolB address and borrow token
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        // Security: ensure this is called from a legitimate pair
        require(sender == address(this), "Invalid sender");
        
        // Decode callback data
        (address poolB, address borrowToken) = abi.decode(data, (address, address));
        
        SimplePair poolAPair = SimplePair(msg.sender);
        SimplePair poolBPair = SimplePair(poolB);
        
        address token0 = poolAPair.token0();
        address token1 = poolAPair.token1();
        
        // Determine which token we borrowed and which we need to repay with
        uint256 amountBorrowed = amount0 > 0 ? amount0 : amount1;
        address repayToken = borrowToken == token0 ? token1 : token0;
        
        // Step 1: We now have 'amountBorrowed' of 'borrowToken'
        // Step 2: Swap borrowed tokens on PoolB
        // Transfer borrowed tokens to PoolB
        IERC20(borrowToken).transfer(poolB, amountBorrowed);
        
        // Determine output amounts for swap on PoolB
        (uint112 reserveB0, uint112 reserveB1,) = poolBPair.getReserves();
        address token0B = poolBPair.token0();
        
        uint256 amountIn = amountBorrowed;
        uint256 amountOut;
        
        if (borrowToken == token0B) {
            // Borrowed token is token0 in PoolB, we get token1
            amountOut = getAmountOut(amountIn, uint256(reserveB0), uint256(reserveB1));
            poolBPair.swap(0, amountOut, address(this), new bytes(0));
        } else {
            // Borrowed token is token1 in PoolB, we get token0
            amountOut = getAmountOut(amountIn, uint256(reserveB1), uint256(reserveB0));
            poolBPair.swap(amountOut, 0, address(this), new bytes(0));
        }
        
        uint256 amountReceived = amountOut;
        
        // Step 3: Calculate how much we need to repay to PoolA
        // Uniswap V2 fee is 0.3%, so we need to repay: (amountBorrowed * 1000) / 997
        uint256 amountToRepay = ((amountBorrowed * 1000) / 997) + 1; // +1 to handle rounding
        
        // Step 4: Repay PoolA
        require(amountReceived >= amountToRepay, "Insufficient profit - arbitrage not profitable");
        
        IERC20(repayToken).transfer(msg.sender, amountToRepay);
        
        // Step 5: Calculate and keep profit
        uint256 profit = amountReceived - amountToRepay;
        
        if (repayToken == token0) {
            totalProfitTokenA += profit;
        } else {
            totalProfitTokenB += profit;
        }
        
        emit ArbitrageExecuted(
            msg.sender, // poolA
            poolB,
            amountBorrowed,
            profit,
            repayToken
        );
    }
    
    /**
     * @dev Calculate amount out for a swap (Uniswap V2 formula)
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    /**
     * @dev Withdraw profits (owner only)
     */
    function withdrawToken(address token, uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        IERC20(token).transfer(owner, amount);
    }
    
    /**
     * @dev Get contract's token balance
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
