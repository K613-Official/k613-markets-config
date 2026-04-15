// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {K613Monad_InitialListing} from "../src/payloads/K613Monad_InitialListing.sol";
import {K613PayloadMonad} from "../src/payloads/K613PayloadMonad.sol";
import {IAaveV3ConfigEngine} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol";
import {EngineFlags} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/EngineFlags.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title K613Monad_InitialListingTest
/// @notice Verifies the declarative `Listing[]` produced by the initial Monad payload.
contract K613Monad_InitialListingTest is Test {
    K613Monad_InitialListing internal payload;

    function setUp() public {
        payload = new K613Monad_InitialListing();
    }

    function test_BindsMonadConfigEngine() public view {
        assertEq(address(payload.CONFIG_ENGINE()), MonadMainnet.CONFIG_ENGINE, "engine mismatch");
    }

    function test_PoolContextIsMonad() public view {
        IAaveV3ConfigEngine.PoolContext memory ctx = payload.getPoolContext();
        assertEq(ctx.networkName, "Monad");
        assertEq(ctx.networkAbbreviation, "Mon");
    }

    function test_ListsElevenAssets() public view {
        IAaveV3ConfigEngine.Listing[] memory listings = payload.newListings();
        assertEq(listings.length, 11, "expected 11 reserves");
    }

    function test_EveryListingWellFormed() public view {
        IAaveV3ConfigEngine.Listing[] memory listings = payload.newListings();

        for (uint256 i = 0; i < listings.length; i++) {
            IAaveV3ConfigEngine.Listing memory l = listings[i];

            assertNotEq(l.asset, address(0), "asset zero");
            assertNotEq(l.priceFeed, address(0), "feed zero");
            assertGt(bytes(l.assetSymbol).length, 0, "empty symbol");

            assertGt(l.rateStrategyParams.optimalUsageRatio, 0, "optimal usage zero");
            assertGt(l.rateStrategyParams.variableRateSlope1, 0, "slope1 zero");
            assertGt(l.rateStrategyParams.variableRateSlope2, 0, "slope2 zero");

            assertEq(l.enabledToBorrow, EngineFlags.ENABLED, "borrow disabled");
            assertEq(l.flashloanable, EngineFlags.ENABLED, "flashloan disabled");

            assertLe(l.ltv, 10_000, "ltv > 100%");
            assertLe(l.liqThreshold, 10_000, "lt > 100%");
            assertLe(l.ltv, l.liqThreshold, "ltv > lt");
            assertGt(l.liqBonus, 0, "liqBonus zero");
            assertLe(l.reserveFactor, 10_000, "rf > 100%");

            assertGt(l.supplyCap, 0, "supplyCap zero");
            assertGt(l.borrowCap, 0, "borrowCap zero");
            assertGe(l.supplyCap, l.borrowCap, "supply < borrow");
        }
    }

    function test_AssetsAreUnique() public view {
        IAaveV3ConfigEngine.Listing[] memory listings = payload.newListings();
        for (uint256 i = 0; i < listings.length; i++) {
            for (uint256 j = i + 1; j < listings.length; j++) {
                assertNotEq(listings[i].asset, listings[j].asset, "duplicate asset");
            }
        }
    }
}
