// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {K613PayloadMonad} from "./K613PayloadMonad.sol";
import {IAaveV3ConfigEngine} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol";
import {EngineFlags} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/EngineFlags.sol";

/// @title K613Monad_InitialListing
/// @notice One-shot payload that lists the 11 canonical Monad mainnet reserves via the config engine.
contract K613Monad_InitialListing is K613PayloadMonad {
    address internal constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
    address internal constant USDC_FEED = 0xf5F15f188AbCB0d165D1Edb7f37F7d6fA2fCebec;

    address internal constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address internal constant AUSD_FEED = 0xE20751C7B5867bCBef815ffc1b284c3f412a9e13;

    address internal constant WSTETH = 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417;
    address internal constant WSTETH_FEED = 0xe6cd21b31948503dB54A07875999979722504B9A;

    address internal constant WETH = 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242;
    address internal constant WETH_FEED = 0x1B1414782B859871781bA3E4B0979b9ca57A0A04;

    address internal constant USDT0 = 0xe7cd86e13AC4309349F30B3435a9d337750fC82D;
    address internal constant USDT0_FEED = 0x1a1Be4c184923a6BFF8c27cfDf6ac8bDE4DE00FC;

    address internal constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    address internal constant WSRUSD_FEED = 0x99bb13E956ba6e25624cAe95A41ED705AeA2557d;

    address internal constant WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address internal constant WBTC_FEED = 0x2D1Df1bD061AAc38C22407AD69d69bCC3C62edBD;

    address internal constant WMON = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;
    address internal constant WMON_FEED = 0xBcD78f76005B7515837af6b50c7C52BCf73822fb;

    address internal constant SHMON = 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c;
    address internal constant SHMON_FEED = 0x7A496d8ba15F82E35F3c633b6292eE75c4F5EDDB;

    address internal constant SMON = 0xA3227C5969757783154C60bF0bC1944180ed81B9;
    address internal constant SMON_FEED = 0x23164e7B0D502E1EeB67C1b05201315372e7516E;

    address internal constant GMON = 0x8498312A6B3CbD158bf0c93AbdCF29E6e4F55081;
    address internal constant GMON_FEED = 0xdF3B3317974b2BA329377C7242C6A8e99A99E993;

    /// @notice Declares the full initial reserve listing batch for Monad mainnet.
    /// @return listings Eleven `Listing` structs with feeds, caps, and risk parameters.
    function newListings() public pure override returns (IAaveV3ConfigEngine.Listing[] memory listings) {
        listings = new IAaveV3ConfigEngine.Listing[](11);

        listings[0] = _stablecoin(USDC, "USDC", USDC_FEED, 200_000, 250_000);
        listings[1] = _stablecoin(AUSD, "AUSD", AUSD_FEED, 150_000, 200_000);
        listings[2] = _stablecoin(USDT0, "USDT0", USDT0_FEED, 80_000, 100_000);
        listings[3] = _stablecoin(WSRUSD, "WSRUSD", WSRUSD_FEED, 50_000, 65_000);

        listings[4] = _weth(WETH, "WETH", WETH_FEED, 40, 55);
        listings[5] = _wstEth(WSTETH, "wstETH", WSTETH_FEED, 40, 55);

        listings[6] = _btc(WBTC, "WBTC", WBTC_FEED, 1, 2);

        listings[7] = _wmon(WMON, "WMON", WMON_FEED, 1_200_000, 1_500_000);

        listings[8] = _monLst(SHMON, "SHMON", SHMON_FEED, 600_000, 800_000);
        listings[9] = _monLst(SMON, "SMON", SMON_FEED, 200_000, 300_000);
        listings[10] = _monLst(GMON, "GMON", GMON_FEED, 200_000, 300_000);
    }

    /// @dev Stablecoin rate curve: low base (1%), gentle slope, steep penalty past optimal.
    function _stableRate() private pure returns (IAaveV3ConfigEngine.InterestRateInputData memory) {
        return IAaveV3ConfigEngine.InterestRateInputData({
            optimalUsageRatio: 90_00, baseVariableBorrowRate: 1_00, variableRateSlope1: 4_00, variableRateSlope2: 75_00
        });
    }

    /// @dev Blue-chip rate curve (WETH, wstETH, WBTC): low base, moderate slopes.
    function _blueChipRate() private pure returns (IAaveV3ConfigEngine.InterestRateInputData memory) {
        return IAaveV3ConfigEngine.InterestRateInputData({
            optimalUsageRatio: 80_00, baseVariableBorrowRate: 1_00, variableRateSlope1: 3_50, variableRateSlope2: 80_00
        });
    }

    /// @dev Volatile rate curve (WMON, SHMON, SMON, GMON): higher base, steep slopes.
    function _volatileRate() private pure returns (IAaveV3ConfigEngine.InterestRateInputData memory) {
        return IAaveV3ConfigEngine.InterestRateInputData({
            optimalUsageRatio: 65_00, baseVariableBorrowRate: 5_00, variableRateSlope1: 7_00, variableRateSlope2: 100_00
        });
    }

    /// @dev Assembles a `Listing` from risk inputs and a rate strategy for this payload.
    function _build(
        address asset,
        string memory symbol,
        address feed,
        uint256 borrowCap,
        uint256 supplyCap,
        uint256 ltv,
        uint256 liqThreshold,
        uint256 liqBonus,
        uint256 reserveFactor,
        uint256 borrowableInIsolation,
        IAaveV3ConfigEngine.InterestRateInputData memory rate
    ) private pure returns (IAaveV3ConfigEngine.Listing memory) {
        return IAaveV3ConfigEngine.Listing({
            asset: asset,
            assetSymbol: symbol,
            priceFeed: feed,
            rateStrategyParams: rate,
            enabledToBorrow: EngineFlags.ENABLED,
            borrowableInIsolation: borrowableInIsolation,
            withSiloedBorrowing: EngineFlags.DISABLED,
            flashloanable: EngineFlags.ENABLED,
            ltv: ltv,
            liqThreshold: liqThreshold,
            liqBonus: liqBonus,
            reserveFactor: reserveFactor,
            supplyCap: supplyCap,
            borrowCap: borrowCap,
            debtCeiling: 0,
            liqProtocolFee: 10_00
        });
    }

    /// @dev Stablecoin profile: LTV 77%, LT 80%, liquidation bonus 5%, reserve factor 25%, isolation borrow on.
    function _stablecoin(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(
            asset, symbol, feed, borrowCap, supplyCap, 77_00, 80_00, 5_00, 25_00, EngineFlags.ENABLED, _stableRate()
        );
    }

    /// @dev WETH profile: LTV 75%, LT 79%, liquidation bonus 6%, reserve factor 25%.
    function _weth(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(
            asset, symbol, feed, borrowCap, supplyCap, 75_00, 79_00, 6_00, 25_00, EngineFlags.DISABLED, _blueChipRate()
        );
    }

    /// @dev wstETH profile: LTV 73%, LT 78%, liquidation bonus 6%, reserve factor 25% (LST basis risk vs WETH).
    function _wstEth(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(
            asset, symbol, feed, borrowCap, supplyCap, 73_00, 78_00, 6_00, 25_00, EngineFlags.DISABLED, _blueChipRate()
        );
    }

    /// @dev WBTC profile: LTV 68%, LT 74%, liquidation bonus 7%, reserve factor 25%.
    function _btc(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(
            asset, symbol, feed, borrowCap, supplyCap, 68_00, 74_00, 7_00, 25_00, EngineFlags.DISABLED, _blueChipRate()
        );
    }

    /// @dev WMON profile: LTV 60%, LT 68%, liquidation bonus 5%, reserve factor 50% (volatile native base).
    function _wmon(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(
            asset, symbol, feed, borrowCap, supplyCap, 60_00, 68_00, 5_00, 50_00, EngineFlags.DISABLED, _volatileRate()
        );
    }

    /// @dev MON-LST profile (SHMON / SMON / GMON): LTV 55%, LT 60%, liquidation bonus 5%, reserve factor 50%.
    function _monLst(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(
            asset, symbol, feed, borrowCap, supplyCap, 55_00, 60_00, 5_00, 50_00, EngineFlags.DISABLED, _volatileRate()
        );
    }
}
