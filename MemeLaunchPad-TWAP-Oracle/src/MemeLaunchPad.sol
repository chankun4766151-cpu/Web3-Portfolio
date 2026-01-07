// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MemeToken.sol";
import "./TWAPOracle.sol";

/**
 * @title MemeLaunchPad
 * @dev Factory contract for deploying Meme tokens with integrated TWAP oracle and AMM functionality
 */
contract MemeLaunchPad {
    TWAPOracle public immutable oracle;

    struct Pool {
        uint256 tokenReserve;
        uint256 ethReserve;
        bool exists;
    }

    // Mapping from token address to its liquidity pool
    mapping(address => Pool) public pools;
    
    // Array of all deployed tokens
    address[] public deployedTokens;

    event MemeTokenCreated(
        address indexed token,
        string name,
        string symbol,
        uint256 initialSupply,
        address creator
    );

    event LiquidityAdded(
        address indexed token,
        uint256 tokenAmount,
        uint256 ethAmount
    );

    event Swap(
        address indexed token,
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        bool isEthToToken,
        uint256 newPrice
    );

    constructor() {
        oracle = new TWAPOracle();
    }

    /**
     * @dev Create a new Meme token
     * @param name Token name
     * @param symbol Token symbol
     * @param initialSupply Initial token supply (in wei units)
     */
    function createMeme(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) external returns (address) {
        MemeToken token = new MemeToken(name, symbol, initialSupply, msg.sender);
        deployedTokens.push(address(token));

        emit MemeTokenCreated(
            address(token),
            name,
            symbol,
            initialSupply,
            msg.sender
        );

        return address(token);
    }

    /**
     * @dev Add liquidity to a token pool
     * @param token Address of the token
     * @param tokenAmount Amount of tokens to add
     */
    function addLiquidity(address token, uint256 tokenAmount) external payable {
        require(msg.value > 0, "Must send ETH");
        require(tokenAmount > 0, "Must send tokens");

        // Transfer tokens from user to this contract
        MemeToken(token).transferFrom(msg.sender, address(this), tokenAmount);

        Pool storage pool = pools[token];
        pool.tokenReserve += tokenAmount;
        pool.ethReserve += msg.value;
        pool.exists = true;

        // Calculate and update initial price: ETH per token (with 18 decimals)
        uint256 price = (pool.ethReserve * 1e18) / pool.tokenReserve;
        oracle.update(token, price);

        emit LiquidityAdded(token, tokenAmount, msg.value);
    }

    /**
     * @dev Swap tokens using constant product formula (x * y = k)
     * @param token Address of the token to swap
     * @param amountIn Amount of input tokens
     * @param isEthToToken True if swapping ETH for tokens, false if swapping tokens for ETH
     */
    function swap(
        address token,
        uint256 amountIn,
        bool isEthToToken
    ) external payable returns (uint256 amountOut) {
        Pool storage pool = pools[token];
        require(pool.exists, "Pool does not exist");

        if (isEthToToken) {
            require(msg.value == amountIn, "Incorrect ETH amount");
            
            // Calculate token output using constant product formula
            // amountOut = (tokenReserve * amountIn) / (ethReserve + amountIn)
            amountOut = (pool.tokenReserve * amountIn) / (pool.ethReserve + amountIn);
            require(amountOut > 0, "Insufficient output amount");
            require(amountOut < pool.tokenReserve, "Insufficient liquidity");

            // Update reserves
            pool.ethReserve += amountIn;
            pool.tokenReserve -= amountOut;

            // Transfer tokens to user
            MemeToken(token).transfer(msg.sender, amountOut);
        } else {
            // Calculate ETH output
            // amountOut = (ethReserve * amountIn) / (tokenReserve + amountIn)
            amountOut = (pool.ethReserve * amountIn) / (pool.tokenReserve + amountIn);
            require(amountOut > 0, "Insufficient output amount");
            require(amountOut < pool.ethReserve, "Insufficient liquidity");

            // Transfer tokens from user
            MemeToken(token).transferFrom(msg.sender, address(this), amountIn);

            // Update reserves
            pool.tokenReserve += amountIn;
            pool.ethReserve -= amountOut;

            // Transfer ETH to user
            payable(msg.sender).transfer(amountOut);
        }

        // Update price in oracle: ETH per token
        uint256 newPrice = (pool.ethReserve * 1e18) / pool.tokenReserve;
        oracle.update(token, newPrice);

        emit Swap(token, msg.sender, amountIn, amountOut, isEthToToken, newPrice);
    }

    /**
     * @dev Get current price for a token from the pool
     * @param token Address of the token
     * @return price Current price (ETH per token with 18 decimals)
     */
    function getPrice(address token) external view returns (uint256 price) {
        Pool memory pool = pools[token];
        require(pool.exists, "Pool does not exist");
        return (pool.ethReserve * 1e18) / pool.tokenReserve;
    }

    /**
     * @dev Get pool reserves
     * @param token Address of the token
     * @return tokenReserve Token reserve amount
     * @return ethReserve ETH reserve amount
     */
    function getReserves(address token) 
        external 
        view 
        returns (uint256 tokenReserve, uint256 ethReserve) 
    {
        Pool memory pool = pools[token];
        return (pool.tokenReserve, pool.ethReserve);
    }

    /**
     * @dev Get number of deployed tokens
     */
    function getDeployedTokensCount() external view returns (uint256) {
        return deployedTokens.length;
    }

    /**
     * @dev Get deployed token address by index
     */
    function getDeployedToken(uint256 index) external view returns (address) {
        require(index < deployedTokens.length, "Index out of bounds");
        return deployedTokens[index];
    }
}
