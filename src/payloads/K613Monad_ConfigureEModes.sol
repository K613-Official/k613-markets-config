// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {K613PayloadMonad} from "./K613PayloadMonad.sol";
import {IAaveV3ConfigEngine} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol";
import {EngineFlags} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/EngineFlags.sol";

/// @title K613Monad_ConfigureEModes
/// @notice Introduces ETH-correlated and Stablecoin eMode categories and assigns listed
///         blue-chip reserves to them. Users opting into a category enjoy higher ltv/lt
///         when both collateral and borrow stay inside the category.
/// @dev Category layout:
///        1 — ETH-correlated (WETH, wstETH)
///        2 — Stablecoins (USDC, AUSD, USDT0, WSRUSD)
contract K613Monad_ConfigureEModes is K613PayloadMonad {
    uint8 internal constant EMODE_ETH = 1;
    uint8 internal constant EMODE_STABLE = 2;

    address internal constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
    address internal constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address internal constant USDT0 = 0xe7cd86e13AC4309349F30B3435a9d337750fC82D;
    address internal constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    address internal constant WETH = 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242;
    address internal constant WSTETH = 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417;

    /// @notice Declares the two eMode categories (ETH-correlated and stablecoins) with shared risk params.
    /// @return updates Category rows passed to the config engine.
    function eModeCategoriesUpdates()
        public
        pure
        override
        returns (IAaveV3ConfigEngine.EModeCategoryUpdate[] memory updates)
    {
        updates = new IAaveV3ConfigEngine.EModeCategoryUpdate[](2);
        updates[0] = IAaveV3ConfigEngine.EModeCategoryUpdate({
            eModeCategory: EMODE_ETH, ltv: 93_00, liqThreshold: 95_00, liqBonus: 1_00, label: "ETH correlated"
        });
        updates[1] = IAaveV3ConfigEngine.EModeCategoryUpdate({
            eModeCategory: EMODE_STABLE, ltv: 93_00, liqThreshold: 95_00, liqBonus: 1_00, label: "Stablecoins"
        });
    }

    /// @notice Maps blue-chip assets to the ETH or stable eMode category for this deployment.
    /// @return updates Asset-to-category bindings consumed by the engine.
    function assetsEModeUpdates() public pure override returns (IAaveV3ConfigEngine.AssetEModeUpdate[] memory updates) {
        updates = new IAaveV3ConfigEngine.AssetEModeUpdate[](6);

        updates[0] = IAaveV3ConfigEngine.AssetEModeUpdate({
            asset: WETH, eModeCategory: EMODE_ETH, borrowable: EngineFlags.ENABLED, collateral: EngineFlags.ENABLED
        });
        updates[1] = IAaveV3ConfigEngine.AssetEModeUpdate({
            asset: WSTETH, eModeCategory: EMODE_ETH, borrowable: EngineFlags.ENABLED, collateral: EngineFlags.ENABLED
        });

        updates[2] = IAaveV3ConfigEngine.AssetEModeUpdate({
            asset: USDC, eModeCategory: EMODE_STABLE, borrowable: EngineFlags.ENABLED, collateral: EngineFlags.ENABLED
        });
        updates[3] = IAaveV3ConfigEngine.AssetEModeUpdate({
            asset: AUSD, eModeCategory: EMODE_STABLE, borrowable: EngineFlags.ENABLED, collateral: EngineFlags.ENABLED
        });
        updates[4] = IAaveV3ConfigEngine.AssetEModeUpdate({
            asset: USDT0, eModeCategory: EMODE_STABLE, borrowable: EngineFlags.ENABLED, collateral: EngineFlags.ENABLED
        });
        updates[5] = IAaveV3ConfigEngine.AssetEModeUpdate({
            asset: WSRUSD, eModeCategory: EMODE_STABLE, borrowable: EngineFlags.ENABLED, collateral: EngineFlags.ENABLED
        });
    }
}
