// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorInterface} from "lib/K613-Protocol/src/contracts/dependencies/chainlink/AggregatorInterface.sol";

/// @title ExchangeRateAdapter
/// @notice Combines a token/MON exchange rate feed with MON/USD price feed
///         to produce a token/USD price compatible with AaveOracle.
/// @dev price = (exchangeRate × monUsdPrice) / 10^exchangeRateDecimals
contract ExchangeRateAdapter is AggregatorInterface {
    error ZeroExchangeRateFeed();
    error ZeroMonUsdFeed();

    address private constant ZERO_ADDRESS = address(0);
    int256 private constant ZERO_PRICE = 0;
    uint80 private constant STATIC_ROUND_ID = 1;

    AggregatorInterface public immutable exchangeRateFeed;
    AggregatorInterface public immutable monUsdFeed;
    uint8 private immutable _decimals;
    string private _description;

    /// @param _exchangeRateFeed Chainlink feed returning token/MON exchange rate
    /// @param _monUsdFeed Chainlink MON/USD price feed

    constructor(address _exchangeRateFeed, address _monUsdFeed, string memory description_) {
        if (_exchangeRateFeed == ZERO_ADDRESS) revert ZeroExchangeRateFeed();
        if (_monUsdFeed == ZERO_ADDRESS) revert ZeroMonUsdFeed();
        exchangeRateFeed = AggregatorInterface(_exchangeRateFeed);
        monUsdFeed = AggregatorInterface(_monUsdFeed);
        _description = description_;
        _decimals = monUsdFeed.decimals();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    /// @notice Returns token/USD = exchangeRate × MON/USD / exchangeRateDecimals
    function latestAnswer() external view override returns (int256) {
        int256 rate = exchangeRateFeed.latestAnswer();
        int256 monPrice = monUsdFeed.latestAnswer();
        if (rate <= ZERO_PRICE || monPrice <= ZERO_PRICE) return ZERO_PRICE;

        uint8 rateDecimals = exchangeRateFeed.decimals();
        return (rate * monPrice) / int256(10 ** uint256(rateDecimals));
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (, int256 rate,, uint256 rateUpdatedAt,) = exchangeRateFeed.latestRoundData();
        (, int256 monPrice,, uint256 monUpdatedAt,) = monUsdFeed.latestRoundData();

        int256 price = ZERO_PRICE;
        if (rate > ZERO_PRICE && monPrice > ZERO_PRICE) {
            uint8 rateDecimals = exchangeRateFeed.decimals();
            price = (rate * monPrice) / int256(10 ** uint256(rateDecimals));
        }

        uint256 oldestUpdate = rateUpdatedAt < monUpdatedAt ? rateUpdatedAt : monUpdatedAt;
        return (STATIC_ROUND_ID, price, oldestUpdate, oldestUpdate, STATIC_ROUND_ID);
    }

    function getRoundData(uint80)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return this.latestRoundData();
    }

    function latestTimestamp() external view override returns (uint256) {
        (,,, uint256 rateUpdatedAt,) = exchangeRateFeed.latestRoundData();
        (,,, uint256 monUpdatedAt,) = monUsdFeed.latestRoundData();
        return rateUpdatedAt < monUpdatedAt ? rateUpdatedAt : monUpdatedAt;
    }

    function latestRound() external view override returns (uint256) {
        return uint256(STATIC_ROUND_ID);
    }

    function getAnswer(uint256) external view override returns (int256) {
        return this.latestAnswer();
    }

    function getTimestamp(uint256) external view override returns (uint256) {
        return this.latestTimestamp();
    }
}
