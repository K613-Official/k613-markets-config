// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IncentivesConfig} from "../../src/incentives/IncentivesConfig.sol";

/// @title SetIncentivesWeights
/// @notice One-shot script that writes the canonical supply/borrow bps split to IncentivesConfig.
/// @dev Broadcaster must be the current `admin` of the target IncentivesConfig instance.
///      Env var: INCENTIVES_CONFIG — address of the deployed IncentivesConfig contract.
contract SetIncentivesWeights is Script {
    address internal constant USDC = 0x754704Bc059F8C67012fEd69BC8A327a5aafb603;
    address internal constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address internal constant USDT0 = 0xe7cd86e13AC4309349F30B3435a9d337750fC82D;
    address internal constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    address internal constant WETH = 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242;
    address internal constant WSTETH = 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417;
    address internal constant WBTC = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;
    address internal constant WMON = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;
    address internal constant SHMON = 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c;
    address internal constant SMON = 0xA3227C5969757783154C60bF0bC1944180ed81B9;
    address internal constant GMON = 0x8498312A6B3CbD158bf0c93AbdCF29E6e4F55081;

    /// @notice Canonical 11-asset 65/35 (supply/borrow) weight vector in bps.
    /// @dev Pure getter so tests can assert the snapshot without broadcasting.
    function canonicalWeights() public pure returns (IncentivesConfig.AssetWeight[] memory weights) {
        weights = new IncentivesConfig.AssetWeight[](11);

        //                                                   supplyBps  borrowBps   total
        weights[0] = IncentivesConfig.AssetWeight(USDC, 1400, 700); // 21%
        weights[1] = IncentivesConfig.AssetWeight(AUSD, 1300, 600); // 19%
        weights[2] = IncentivesConfig.AssetWeight(USDT0, 450, 300); // 7.5%
        weights[3] = IncentivesConfig.AssetWeight(WSRUSD, 500, 300); // 8%
        weights[4] = IncentivesConfig.AssetWeight(WETH, 1000, 500); // 15%
        weights[5] = IncentivesConfig.AssetWeight(WSTETH, 850, 400); // 12.5%
        weights[6] = IncentivesConfig.AssetWeight(WBTC, 650, 500); // 11.5%
        weights[7] = IncentivesConfig.AssetWeight(WMON, 150, 50); // 2%
        weights[8] = IncentivesConfig.AssetWeight(SHMON, 100, 50); // 1.5%
        weights[9] = IncentivesConfig.AssetWeight(SMON, 50, 50); // 1%
        weights[10] = IncentivesConfig.AssetWeight(GMON, 50, 50); // 1%
        // Total supply: 6500 (65%), borrow: 3500 (35%), sum: 10000 = WEIGHT_BPS
    }

    function run() external {
        address cfgAddr = vm.envAddress("INCENTIVES_CONFIG");
        IncentivesConfig cfg = IncentivesConfig(cfgAddr);

        IncentivesConfig.AssetWeight[] memory weights = canonicalWeights();

        console.log("IncentivesConfig:", cfgAddr);
        console.log("Current admin:", cfg.admin());
        console.log("Writing 11 asset weights (65% supply / 35% borrow split)");

        vm.startBroadcast();
        cfg.setWeights(weights);
        vm.stopBroadcast();

        console.log("Stored weightCount:", cfg.weightCount());
    }
}
