// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {K613Monad_ConfigureEModes} from "../src/payloads/K613Monad_ConfigureEModes.sol";
import {IAaveV3ConfigEngine} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol";
import {EngineFlags} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/EngineFlags.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title K613Monad_ConfigureEModesTest
/// @notice Static checks on the eMode payload shape and engine wiring (no fork).
contract K613Monad_ConfigureEModesTest is Test {
    K613Monad_ConfigureEModes internal payload;

    address internal constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
    address internal constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address internal constant USDT0 = 0xe7cd86e13AC4309349F30B3435a9d337750fC82D;
    address internal constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    address internal constant WETH = 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242;
    address internal constant WSTETH = 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417;

    function setUp() public {
        payload = new K613Monad_ConfigureEModes();
    }

    function test_BindsMonadConfigEngine() public view {
        assertEq(address(payload.CONFIG_ENGINE()), MonadMainnet.CONFIG_ENGINE, "engine mismatch");
    }

    function test_CreatesTwoEModeCategories() public view {
        IAaveV3ConfigEngine.EModeCategoryUpdate[] memory updates = payload.eModeCategoriesUpdates();
        assertEq(updates.length, 2, "expected 2 categories");

        assertEq(updates[0].eModeCategory, 1);
        assertEq(updates[0].ltv, 93_00);
        assertEq(updates[0].liqThreshold, 95_00);
        assertEq(updates[0].liqBonus, 1_00);
        assertEq(updates[0].label, "ETH correlated");

        assertEq(updates[1].eModeCategory, 2);
        assertEq(updates[1].ltv, 93_00);
        assertEq(updates[1].liqThreshold, 95_00);
        assertEq(updates[1].liqBonus, 1_00);
        assertEq(updates[1].label, "Stablecoins");
    }

    function test_EModeCategoriesAreWellFormed() public view {
        IAaveV3ConfigEngine.EModeCategoryUpdate[] memory updates = payload.eModeCategoriesUpdates();
        for (uint256 i = 0; i < updates.length; i++) {
            assertLe(updates[i].ltv, updates[i].liqThreshold, "ltv > lt");
            assertLe(updates[i].liqThreshold, 10_000, "lt > 100%");
            assertGt(updates[i].liqBonus, 0, "liqBonus zero");
            assertGt(bytes(updates[i].label).length, 0, "empty label");
        }
    }

    function test_AssignsSixAssets() public view {
        IAaveV3ConfigEngine.AssetEModeUpdate[] memory updates = payload.assetsEModeUpdates();
        assertEq(updates.length, 6, "expected 6 asset assignments");
    }

    function test_EthAssetsInCategoryOne() public view {
        IAaveV3ConfigEngine.AssetEModeUpdate[] memory updates = payload.assetsEModeUpdates();
        (address a0, address a1) = (updates[0].asset, updates[1].asset);
        assertTrue(
            (a0 == WETH && a1 == WSTETH) || (a0 == WSTETH && a1 == WETH), "ETH bucket must contain WETH + wstETH"
        );
        assertEq(updates[0].eModeCategory, 1);
        assertEq(updates[1].eModeCategory, 1);
    }

    function test_StableAssetsInCategoryTwo() public view {
        IAaveV3ConfigEngine.AssetEModeUpdate[] memory updates = payload.assetsEModeUpdates();
        for (uint256 i = 2; i < 6; i++) {
            assertEq(updates[i].eModeCategory, 2, "stable in wrong category");
            address a = updates[i].asset;
            assertTrue(a == USDC || a == AUSD || a == USDT0 || a == WSRUSD, "unexpected stable asset");
        }
    }

    function test_AllAssignmentsBorrowableAndCollateral() public view {
        IAaveV3ConfigEngine.AssetEModeUpdate[] memory updates = payload.assetsEModeUpdates();
        for (uint256 i = 0; i < updates.length; i++) {
            assertEq(updates[i].borrowable, EngineFlags.ENABLED, "not borrowable");
            assertEq(updates[i].collateral, EngineFlags.ENABLED, "not collateral");
            assertNotEq(updates[i].asset, address(0), "asset zero");
        }
    }

    function test_AssetsAreUnique() public view {
        IAaveV3ConfigEngine.AssetEModeUpdate[] memory updates = payload.assetsEModeUpdates();
        for (uint256 i = 0; i < updates.length; i++) {
            for (uint256 j = i + 1; j < updates.length; j++) {
                assertNotEq(updates[i].asset, updates[j].asset, "duplicate asset");
            }
        }
    }
}
