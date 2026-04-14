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
    address internal constant SHMON_FEED = 0x4f9ba5CaE0e3F651821283EC4e303fE8D1dA542a;

    address internal constant SMON = 0xA3227C5969757783154C60bF0bC1944180ed81B9;
    address internal constant SMON_FEED = 0x80Efb6394E142F778cdD7F59b6Ee484B5a6299EB;

    address internal constant GMON = 0x8498312A6B3CbD158bf0c93AbdCF29E6e4F55081;
    address internal constant GMON_FEED = 0xE53969561603a9052E3F579b2992C12F3C783496;

    /// @notice Declares the full initial reserve listing batch for Monad mainnet.
    /// @return listings Eleven `Listing` structs with feeds, caps, and risk parameters.
    function newListings() public pure override returns (IAaveV3ConfigEngine.Listing[] memory listings) {
        listings = new IAaveV3ConfigEngine.Listing[](11);

        listings[0] = _stablecoin(USDC, "USDC", USDC_FEED, 200_000, 250_000);
        listings[1] = _stablecoin(AUSD, "AUSD", AUSD_FEED, 200_000, 250_000);
        listings[2] = _stablecoin(USDT0, "USDT0", USDT0_FEED, 200_000, 250_000);
        listings[3] = _stablecoin(WSRUSD, "WSRUSD", WSRUSD_FEED, 120_000, 150_000);

        listings[4] = _weth(WETH, "WETH", WETH_FEED, 120_000, 150_000);
        listings[5] = _wstEth(WSTETH, "wstETH", WSTETH_FEED, 150_000, 190_000);

        listings[6] = _btc(WBTC, "WBTC", WBTC_FEED, 70_000, 90_000);

        listings[7] = _wmon(WMON, "WMON", WMON_FEED, 30_000, 40_000);

        listings[8] = _shmon(SHMON, "SHMON", SHMON_FEED, 30_000, 40_000);
        listings[9] = _smonLike(SMON, "SMON", SMON_FEED, 5_000, 7_000);
        listings[10] = _smonLike(GMON, "GMON", GMON_FEED, 15_000, 20_000);
    }

    /// @dev Default variable-rate curve shared by all initial listings in this payload.
    function _defaultRate() private pure returns (IAaveV3ConfigEngine.InterestRateInputData memory) {
        return IAaveV3ConfigEngine.InterestRateInputData({
            optimalUsageRatio: 80_00, baseVariableBorrowRate: 10_00, variableRateSlope1: 4_00, variableRateSlope2: 60_00
        });
    }

    /// @dev Assembles a `Listing` from risk inputs and shared engine flags for this payload.
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
        uint256 borrowableInIsolation
    ) private pure returns (IAaveV3ConfigEngine.Listing memory) {
        return IAaveV3ConfigEngine.Listing({
            asset: asset,
            assetSymbol: symbol,
            priceFeed: feed,
            rateStrategyParams: _defaultRate(),
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
        return _build(asset, symbol, feed, borrowCap, supplyCap, 77_00, 80_00, 5_00, 25_00, EngineFlags.ENABLED);
    }

    /// @dev WETH profile: LTV 80%, LT 83%, liquidation bonus 7.5%, reserve factor 25%.
    function _weth(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(asset, symbol, feed, borrowCap, supplyCap, 80_00, 83_00, 7_50, 25_00, EngineFlags.DISABLED);
    }

    /// @dev wstETH profile: LTV 78.5%, LT 81%, liquidation bonus 7.5%, reserve factor 25% (LST basis risk vs WETH).
    function _wstEth(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(asset, symbol, feed, borrowCap, supplyCap, 78_50, 81_00, 7_50, 25_00, EngineFlags.DISABLED);
    }

    /// @dev WBTC profile: LTV 73%, LT 78%, liquidation bonus 7.5%, reserve factor 25%.
    function _btc(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(asset, symbol, feed, borrowCap, supplyCap, 73_00, 78_00, 7_50, 25_00, EngineFlags.DISABLED);
    }

    /// @dev WMON profile: LTV 50%, LT 60%, liquidation bonus 10%, reserve factor 50% (volatile native base).
    function _wmon(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(asset, symbol, feed, borrowCap, supplyCap, 50_00, 60_00, 10_00, 50_00, EngineFlags.DISABLED);
    }

    /// @dev SHMON profile: LTV 40%, LT 55%, liquidation bonus 10%, reserve factor 50% (liquid staking on WMON).
    function _shmon(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(asset, symbol, feed, borrowCap, supplyCap, 40_00, 55_00, 10_00, 50_00, EngineFlags.DISABLED);
    }

    /// @dev SMON/GMON profile: LTV 35%, LT 50%, liquidation bonus 12.5%, reserve factor 50% (thin liquidity).
    function _smonLike(address asset, string memory symbol, address feed, uint256 borrowCap, uint256 supplyCap)
        private
        pure
        returns (IAaveV3ConfigEngine.Listing memory)
    {
        return _build(asset, symbol, feed, borrowCap, supplyCap, 35_00, 50_00, 12_50, 50_00, EngineFlags.DISABLED);
    }
}
