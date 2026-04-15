// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {IncentivesConfig} from "../src/incentives/IncentivesConfig.sol";

/// @title IncentivesConfigTest
/// @notice Unit tests for `IncentivesConfig` admin flows, weight sums, and emission math.
contract IncentivesConfigTest is Test {
    IncentivesConfig internal cfg;
    address internal admin = address(0xA11CE);
    address internal stranger = address(0xB0B);

    address internal constant ASSET_A = address(0xAAAA);
    address internal constant ASSET_B = address(0xBBBB);
    address internal constant ASSET_C = address(0xCCCC);

    function setUp() public {
        cfg = new IncentivesConfig(admin);
    }

    function _balanced() internal pure returns (IncentivesConfig.AssetWeight[] memory ws) {
        ws = new IncentivesConfig.AssetWeight[](2);
        ws[0] = IncentivesConfig.AssetWeight({asset: ASSET_A, supplyBps: 4000, borrowBps: 2000});
        ws[1] = IncentivesConfig.AssetWeight({asset: ASSET_B, supplyBps: 2500, borrowBps: 1500});
    }

    function test_DeploysWithAdmin() public view {
        assertEq(cfg.admin(), admin);
        assertEq(cfg.weightCount(), 0);
    }

    function test_YearTotalsAndWeightBps() public view {
        assertEq(cfg.WEIGHT_BPS(), 10_000);
        assertEq(cfg.YEAR1_TOTAL(), 25_000_000e18);
        assertEq(cfg.YEAR2_TOTAL(), 10_000_000e18);
        assertEq(cfg.YEAR3_TOTAL(), 5_000_000e18);
    }

    function test_GetEmissionConfigs_EmptyWeights() public view {
        IncentivesConfig.EmissionConfig[] memory out = cfg.getEmissionConfigs(1e18);
        assertEq(out.length, 0);
    }

    function test_SetAdmin_RevertStranger() public {
        vm.prank(stranger);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setAdmin(address(0xC0DE));
    }

    function test_ConstructorRejectsZeroAdmin() public {
        vm.expectRevert(IncentivesConfig.InvalidAdmin.selector);
        new IncentivesConfig(address(0));
    }

    function test_SetWeightsStoresAndEmits() public {
        IncentivesConfig.AssetWeight[] memory ws = _balanced();
        vm.prank(admin);
        cfg.setWeights(ws);

        assertEq(cfg.weightCount(), 2);
        IncentivesConfig.AssetWeight[] memory stored = cfg.getWeights();
        assertEq(stored[0].asset, ASSET_A);
        assertEq(stored[0].supplyBps, 4000);
        assertEq(stored[1].asset, ASSET_B);
        assertEq(stored[1].borrowBps, 1500);
    }

    function test_SetWeightsReplacesAtomically() public {
        vm.prank(admin);
        cfg.setWeights(_balanced());

        IncentivesConfig.AssetWeight[] memory next = new IncentivesConfig.AssetWeight[](1);
        next[0] = IncentivesConfig.AssetWeight({asset: ASSET_C, supplyBps: 6000, borrowBps: 4000});
        vm.prank(admin);
        cfg.setWeights(next);

        assertEq(cfg.weightCount(), 1);
        assertEq(cfg.getWeights()[0].asset, ASSET_C);
    }

    function test_SetWeightsRevertsOnStranger() public {
        vm.prank(stranger);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setWeights(_balanced());
    }

    function test_SetWeightsRevertsOnEmpty() public {
        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.InvalidWeightsLength.selector);
        cfg.setWeights(new IncentivesConfig.AssetWeight[](0));
    }

    function test_SetWeightsRevertsOnBadSum() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: ASSET_A, supplyBps: 5000, borrowBps: 4000});
        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.InvalidWeightsSum.selector);
        cfg.setWeights(ws);
    }

    function test_SetWeightsRevertsOnZeroAsset() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(0), supplyBps: 6000, borrowBps: 4000});
        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.ZeroAsset.selector);
        cfg.setWeights(ws);
    }

    function test_SetWeightsRevertsOnDuplicate() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](2);
        ws[0] = IncentivesConfig.AssetWeight({asset: ASSET_A, supplyBps: 3000, borrowBps: 3000});
        ws[1] = IncentivesConfig.AssetWeight({asset: ASSET_A, supplyBps: 2000, borrowBps: 2000});
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IncentivesConfig.DuplicateAsset.selector, ASSET_A));
        cfg.setWeights(ws);
    }

    function test_SetAdminTransfersRights() public {
        vm.prank(admin);
        cfg.setAdmin(stranger);
        assertEq(cfg.admin(), stranger);

        vm.prank(stranger);
        cfg.setWeights(_balanced());
    }

    function test_SetAdminRevertsOnZero() public {
        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.InvalidAdmin.selector);
        cfg.setAdmin(address(0));
    }

    function test_GetEmissionConfigsMatchesWeights() public {
        vm.prank(admin);
        cfg.setWeights(_balanced());

        uint256 yearly = 10_000_000e18;
        IncentivesConfig.EmissionConfig[] memory out = cfg.getEmissionConfigs(yearly);
        assertEq(out.length, 2);

        assertEq(out[0].asset, ASSET_A);
        assertEq(out[0].supplyBps, 4000);
        assertEq(out[0].borrowBps, 2000);
        assertEq(uint256(out[0].supplyEmissionPerSecond), ((yearly * 4000) / 10_000) / 365 days);
        assertEq(uint256(out[0].borrowEmissionPerSecond), ((yearly * 2000) / 10_000) / 365 days);
    }
}
