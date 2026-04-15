// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ExchangeRateAdapter} from "../src/adapters/ExchangeRateAdapter.sol";
import {MockChainlinkAggregator} from "./mocks/MockChainlinkAggregator.sol";

contract ExchangeRateAdapterTest is Test {
    MockChainlinkAggregator internal rateFeed;
    MockChainlinkAggregator internal monUsd;
    ExchangeRateAdapter internal adapter;

    function setUp() public {
        rateFeed = new MockChainlinkAggregator(8, int256(2e8));
        monUsd = new MockChainlinkAggregator(8, int256(5e8));
        adapter = new ExchangeRateAdapter(address(rateFeed), address(monUsd), "test / USD");
    }

    function test_ConstructorRevertsOnZeroExchangeFeed() public {
        vm.expectRevert(ExchangeRateAdapter.ZeroExchangeRateFeed.selector);
        new ExchangeRateAdapter(address(0), address(monUsd), "x");
    }

    function test_ConstructorRevertsOnZeroMonFeed() public {
        vm.expectRevert(ExchangeRateAdapter.ZeroMonUsdFeed.selector);
        new ExchangeRateAdapter(address(rateFeed), address(0), "x");
    }

    function test_DecimalsMatchesMonFeed() public view {
        assertEq(adapter.decimals(), 8);
    }

    function test_Description() public view {
        assertEq(adapter.description(), "test / USD");
    }

    function test_LatestAnswer_MultipliesAndScales() public view {
        int256 out = adapter.latestAnswer();
        assertEq(out, int256(10e8));
    }

    function test_LatestAnswer_ReturnsZeroWhenRateNonPositive() public {
        rateFeed.setAnswer(0);
        assertEq(adapter.latestAnswer(), 0);
        rateFeed.setAnswer(-1);
        assertEq(adapter.latestAnswer(), 0);
    }

    function test_LatestAnswer_ReturnsZeroWhenMonNonPositive() public {
        monUsd.setAnswer(0);
        assertEq(adapter.latestAnswer(), 0);
    }

    function test_LatestRoundData_UsesMinTimestamp() public {
        rateFeed.setUpdatedAt(100);
        monUsd.setUpdatedAt(200);
        (, int256 answer,, uint256 updatedAt,) = adapter.latestRoundData();
        assertEq(answer, int256(10e8));
        assertEq(updatedAt, 100);
    }

    function test_GetRoundData_MatchesLatestRoundData() public view {
        (uint80 a0, int256 a1, uint256 a2, uint256 a3, uint80 a4) = adapter.latestRoundData();
        (uint80 b0, int256 b1, uint256 b2, uint256 b3, uint80 b4) = adapter.getRoundData(0);
        assertEq(a0, b0);
        assertEq(a1, b1);
        assertEq(a2, b2);
        assertEq(a3, b3);
        assertEq(a4, b4);
    }

    function test_LatestTimestamp_ReturnsMin() public {
        rateFeed.setUpdatedAt(300);
        monUsd.setUpdatedAt(400);
        assertEq(adapter.latestTimestamp(), 300);
    }

    function test_LatestRound_IsOne() public view {
        assertEq(adapter.latestRound(), 1);
    }

    function test_GetAnswer_GetTimestamp() public {
        rateFeed.setUpdatedAt(555);
        monUsd.setUpdatedAt(777);
        assertEq(adapter.getAnswer(0), int256(10e8));
        assertEq(adapter.getTimestamp(0), 555);
    }
}
