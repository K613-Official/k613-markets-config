// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {StaticRewardPriceFeed} from "../src/incentives/StaticRewardPriceFeed.sol";
import {ExchangeRateAdapter} from "../src/adapters/ExchangeRateAdapter.sol";
import {MockChainlinkAggregator} from "./mocks/MockChainlinkAggregator.sol";

/// @title PriceFeedsFuzzTest
/// @notice Property-based tests for `StaticRewardPriceFeed` and `ExchangeRateAdapter` math.
contract PriceFeedsFuzzTest is Test {
    function testFuzz_StaticFeed_StoresAnswerAndDecimals(int256 answer, uint8 dec) public {
        if (answer <= 0) {
            vm.expectRevert(StaticRewardPriceFeed.ZeroAnswer.selector);
            new StaticRewardPriceFeed(answer, dec, "x");
            return;
        }
        StaticRewardPriceFeed feed = new StaticRewardPriceFeed(answer, dec, "x");
        assertEq(feed.latestAnswer(), answer);
        assertEq(feed.decimals(), dec);
        assertEq(feed.getAnswer(0), answer);
        assertEq(feed.latestRound(), 1);

        (uint80 rid, int256 a, uint256 s, uint256 u, uint80 ar) = feed.latestRoundData();
        assertEq(rid, 1);
        assertEq(a, answer);
        assertEq(s, block.timestamp);
        assertEq(u, block.timestamp);
        assertEq(ar, 1);
    }

    /// @dev Adapter math must equal `rate * monPrice / 10^rateDecimals` whenever both feeds are positive.
    function testFuzz_ExchangeRateAdapter_Math(uint256 rateU, uint256 monPriceU, uint8 rateDecimals) public {
        // Keep rateDecimals in the realistic Chainlink range (0..18) so 10**rateDecimals fits.
        rateDecimals = uint8(bound(uint256(rateDecimals), 0, 18));
        // Bound inputs so the multiplication cannot overflow int256.
        int256 rate = int256(bound(rateU, 1, 1e30));
        int256 monPrice = int256(bound(monPriceU, 1, 1e30));

        MockChainlinkAggregator rateFeed = new MockChainlinkAggregator(rateDecimals, rate);
        MockChainlinkAggregator monUsd = new MockChainlinkAggregator(8, monPrice);
        ExchangeRateAdapter adapter = new ExchangeRateAdapter(address(rateFeed), address(monUsd), "x");

        int256 expected = (rate * monPrice) / int256(10 ** uint256(rateDecimals));
        assertEq(adapter.latestAnswer(), expected);

        (, int256 answer,,,) = adapter.latestRoundData();
        assertEq(answer, expected);
    }

    /// @dev Any non-positive source answer must zero the result.
    function testFuzz_ExchangeRateAdapter_NonPositiveSourceZeroes(int128 rate128, int128 monPrice128) public {
        int256 rate = int256(rate128);
        int256 monPrice = int256(monPrice128);
        vm.assume(rate <= 0 || monPrice <= 0);

        MockChainlinkAggregator rateFeed = new MockChainlinkAggregator(8, int256(1e8));
        MockChainlinkAggregator monUsd = new MockChainlinkAggregator(8, int256(1e8));
        ExchangeRateAdapter adapter = new ExchangeRateAdapter(address(rateFeed), address(monUsd), "x");

        rateFeed.setAnswer(rate);
        monUsd.setAnswer(monPrice);
        assertEq(adapter.latestAnswer(), 0);
        (, int256 a,,,) = adapter.latestRoundData();
        assertEq(a, 0);
    }

    /// @dev `latestTimestamp` must always return the older of the two source timestamps.
    function testFuzz_ExchangeRateAdapter_TimestampIsMinOfSources(uint64 t1, uint64 t2) public {
        MockChainlinkAggregator rateFeed = new MockChainlinkAggregator(8, int256(1e8));
        MockChainlinkAggregator monUsd = new MockChainlinkAggregator(8, int256(1e8));
        ExchangeRateAdapter adapter = new ExchangeRateAdapter(address(rateFeed), address(monUsd), "x");

        rateFeed.setUpdatedAt(t1);
        monUsd.setUpdatedAt(t2);

        uint256 expected = t1 < t2 ? t1 : t2;
        assertEq(adapter.latestTimestamp(), expected);
        (,,, uint256 u,) = adapter.latestRoundData();
        assertEq(u, expected);
    }
}
