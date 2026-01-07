// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleUniswapV2.sol";
import "../src/MyTokenA.sol";
import "../src/MyTokenB.sol";

contract DebugTest is Test {
    function test() public {
        MyTokenA tokenA = new MyTokenA();
        MyTokenB tokenB = new MyTokenB();
        SimpleFactory factory = new SimpleFactory(address(this));
        
        address pair = factory.createPair(address(tokenA), address(tokenB));
        
        SimplePair p = SimplePair(pair);
        
        console.log("TokenA address:", address(tokenA));
        console.log("TokenB address:", address(tokenB));
        console.log("Pair token0:", p.token0());
        console.log("Pair token1:", p.token1());
        
        // Add liquidity: 5000 TokenA, 500000 TokenB
        tokenA.transfer(pair, 5_000 * 10**18);
        tokenB.transfer(pair, 500_000 * 10**18);
        p.mint(address(this));
        
        (uint112 r0, uint112 r1,) = p.getReserves();
        console.log("Reserve0:", uint256(r0) / 10**18);
        console.log("Reserve1:", uint256(r1) / 10**18);
    }
}
