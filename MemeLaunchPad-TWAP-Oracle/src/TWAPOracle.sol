// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TWAPOracle
 * @dev Time-Weighted Average Price Oracle for tracking token prices
 */
contract TWAPOracle {
    struct Observation {
        uint256 timestamp;
        uint256 price; // Price with 18 decimals precision
        uint256 cumulativePrice; // Cumulative price for TWAP calculation
    }

    // Mapping from token address to array of price observations
    mapping(address => Observation[]) public observations;

    event PriceUpdated(
        address indexed token,
        uint256 price,
        uint256 timestamp,
        uint256 cumulativePrice
    );

    /**
     * @dev Update price observation for a token
     * @param token Address of the token
     * @param price Current price (18 decimals)
     */
    function update(address token, uint256 price) external {
        Observation[] storage obs = observations[token];
        
        uint256 currentTime = block.timestamp;
        uint256 cumulativePrice = 0;

        // Calculate cumulative price
        if (obs.length > 0) {
            Observation memory lastObs = obs[obs.length - 1];
            uint256 timeElapsed = currentTime - lastObs.timestamp;
            cumulativePrice = lastObs.cumulativePrice + (lastObs.price * timeElapsed);
        }

        // Add new observation
        obs.push(Observation({
            timestamp: currentTime,
            price: price,
            cumulativePrice: cumulativePrice
        }));

        emit PriceUpdated(token, price, currentTime, cumulativePrice);
    }

    /**
     * @dev Get TWAP for a token over a specified time interval
     * @param token Address of the token
     * @param interval Time interval in seconds
     * @return TWAP price (18 decimals)
     */
    function getTWAP(address token, uint256 interval) external view returns (uint256) {
        Observation[] storage obs = observations[token];
        require(obs.length > 0, "No observations");

        uint256 currentTime = block.timestamp;
        uint256 targetTime = currentTime - interval;

        // Find the observation closest to targetTime
        uint256 startIndex = 0;
        for (uint256 i = obs.length; i > 0; i--) {
            if (obs[i - 1].timestamp <= targetTime) {
                startIndex = i - 1;
                break;
            }
        }

        Observation memory startObs = obs[startIndex];
        Observation memory endObs = obs[obs.length - 1];

        // If we only have one observation or interval is too short
        if (startObs.timestamp == endObs.timestamp) {
            return endObs.price;
        }

        // Calculate TWAP
        uint256 timeElapsed = endObs.timestamp - startObs.timestamp;
        uint256 priceDifference = endObs.cumulativePrice - startObs.cumulativePrice;
        
        // Add the current price contribution
        uint256 currentContribution = endObs.price * (currentTime - endObs.timestamp);
        uint256 totalTimeElapsed = currentTime - startObs.timestamp;

        return (priceDifference + currentContribution) / totalTimeElapsed;
    }

    /**
     * @dev Get the current (latest) price for a token
     * @param token Address of the token
     * @return Current price (18 decimals)
     */
    function getCurrentPrice(address token) external view returns (uint256) {
        Observation[] storage obs = observations[token];
        require(obs.length > 0, "No observations");
        return obs[obs.length - 1].price;
    }

    /**
     * @dev Get total number of observations for a token
     * @param token Address of the token
     * @return Number of observations
     */
    function getObservationCount(address token) external view returns (uint256) {
        return observations[token].length;
    }

    /**
     * @dev Get a specific observation by index
     * @param token Address of the token
     * @param index Index of the observation
     * @return timestamp Timestamp of the observation
     * @return price Price at the observation
     * @return cumulativePrice Cumulative price at the observation
     */
    function getObservation(address token, uint256 index) 
        external 
        view 
        returns (uint256 timestamp, uint256 price, uint256 cumulativePrice) 
    {
        require(index < observations[token].length, "Index out of bounds");
        Observation memory obs = observations[token][index];
        return (obs.timestamp, obs.price, obs.cumulativePrice);
    }
}
