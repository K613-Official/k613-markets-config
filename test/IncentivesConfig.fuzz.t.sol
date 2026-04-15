// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {IncentivesConfig} from "../src/incentives/IncentivesConfig.sol";

/// @title IncentivesConfigFuzzTest
/// @notice Property-based tests for `IncentivesConfig` weight validation and emission math.
contract IncentivesConfigFuzzTest is Test {
    IncentivesConfig internal cfg;
    address internal admin = address(0xA11CE);

    function setUp() public {
        cfg = new IncentivesConfig(admin);
    }

    /// @dev Any single-asset split whose bps components sum to 10_000 must be accepted.
    function testFuzz_SetWeights_SingleAssetValidSplit(address asset, uint256 supplyBps) public {
        vm.assume(asset != address(0));
        supplyBps = bound(supplyBps, 0, 10_000);
        uint256 borrowBps = 10_000 - supplyBps;

        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: asset, supplyBps: supplyBps, borrowBps: borrowBps});

        vm.prank(admin);
        cfg.setWeights(ws);

        IncentivesConfig.AssetWeight[] memory stored = cfg.getWeights();
        assertEq(stored.length, 1);
        assertEq(stored[0].asset, asset);
        assertEq(stored[0].supplyBps, supplyBps);
        assertEq(stored[0].borrowBps, borrowBps);
    }

    /// @dev Any single-asset split whose bps components do not sum to 10_000 must revert.
    function testFuzz_SetWeights_SingleAssetInvalidSplitReverts(address asset, uint16 supplyBps, uint16 borrowBps)
        public
    {
        vm.assume(asset != address(0));
        vm.assume(uint256(supplyBps) + uint256(borrowBps) != 10_000);

        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: asset, supplyBps: supplyBps, borrowBps: borrowBps});

        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.InvalidWeightsSum.selector);
        cfg.setWeights(ws);
    }

    /// @dev Two-asset split is accepted iff components sum to 10_000 and assets are distinct and non-zero.
    function testFuzz_SetWeights_TwoAssetSplit(address a, address b, uint256 s1, uint256 s2) public {
        vm.assume(a != address(0) && b != address(0) && a != b);
        s1 = bound(s1, 0, 10_000);
        s2 = bound(s2, 0, 10_000 - s1);
        uint256 b1 = 0;
        uint256 b2 = 10_000 - s1 - s2;

        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](2);
        ws[0] = IncentivesConfig.AssetWeight({asset: a, supplyBps: s1, borrowBps: b1});
        ws[1] = IncentivesConfig.AssetWeight({asset: b, supplyBps: s2, borrowBps: b2});

        vm.prank(admin);
        cfg.setWeights(ws);

        assertEq(cfg.weightCount(), 2);
    }

    /// @dev Duplicate assets in the batch must always revert regardless of bps distribution.
    function testFuzz_SetWeights_DuplicateAssetAlwaysReverts(address asset, uint256 s1, uint256 s2, uint256 b1) public {
        vm.assume(asset != address(0));
        s1 = bound(s1, 0, 5_000);
        s2 = bound(s2, 0, 5_000);
        b1 = bound(b1, 0, 10_000 - s1 - s2);
        uint256 b2 = 10_000 - s1 - s2 - b1;

        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](2);
        ws[0] = IncentivesConfig.AssetWeight({asset: asset, supplyBps: s1, borrowBps: b1});
        ws[1] = IncentivesConfig.AssetWeight({asset: asset, supplyBps: s2, borrowBps: b2});

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IncentivesConfig.DuplicateAsset.selector, asset));
        cfg.setWeights(ws);
    }

    /// @dev `getEmissionConfigs` must preserve the `yearly * bps / 10_000 / 365 days` invariant for all inputs
    ///      where the resulting per-second emission fits uint88. Bound to 100× the hard-coded YEAR1 total.
    function testFuzz_GetEmissionConfigs_Math(uint256 yearly, uint256 supplyBps) public {
        yearly = bound(yearly, 0, 2_500_000_000e18);
        supplyBps = bound(supplyBps, 0, 10_000);
        uint256 borrowBps = 10_000 - supplyBps;

        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(0xAAAA), supplyBps: supplyBps, borrowBps: borrowBps});

        vm.prank(admin);
        cfg.setWeights(ws);

        IncentivesConfig.EmissionConfig[] memory out = cfg.getEmissionConfigs(yearly);
        assertEq(out.length, 1);

        uint256 expectedSupply = ((yearly * supplyBps) / 10_000) / 365 days;
        uint256 expectedBorrow = ((yearly * borrowBps) / 10_000) / 365 days;
        // Must fit uint88 at realistic input ranges.
        assertLe(expectedSupply, type(uint88).max);
        assertLe(expectedBorrow, type(uint88).max);
        assertEq(uint256(out[0].supplyEmissionPerSecond), expectedSupply);
        assertEq(uint256(out[0].borrowEmissionPerSecond), expectedBorrow);
    }

    /// @dev Sum of per-second emissions across assets must round-trip to (yearly/365 days) ± N (truncation).
    function testFuzz_GetEmissionConfigs_SumBound(uint256 yearly) public {
        yearly = bound(yearly, 0, type(uint88).max * uint256(365 days));

        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](2);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(0xAAAA), supplyBps: 4000, borrowBps: 2000});
        ws[1] = IncentivesConfig.AssetWeight({asset: address(0xBBBB), supplyBps: 2500, borrowBps: 1500});

        vm.prank(admin);
        cfg.setWeights(ws);

        IncentivesConfig.EmissionConfig[] memory out = cfg.getEmissionConfigs(yearly);
        uint256 perSecSum;
        for (uint256 i = 0; i < out.length; i++) {
            perSecSum += uint256(out[i].supplyEmissionPerSecond);
            perSecSum += uint256(out[i].borrowEmissionPerSecond);
        }

        uint256 idealPerSec = yearly / 365 days;
        // Integer division happens per bucket, so rounding loss is bounded by one per bucket (4 buckets).
        assertLe(perSecSum, idealPerSec);
        if (idealPerSec > 4) {
            assertGe(perSecSum, idealPerSec - 4);
        }
    }

    /// @dev Empty array always reverts.
    function testFuzz_SetWeights_EmptyAlwaysReverts(uint8) public {
        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.InvalidWeightsLength.selector);
        cfg.setWeights(new IncentivesConfig.AssetWeight[](0));
    }

    /// @dev Any non-admin caller must be rejected.
    function testFuzz_SetWeights_OnlyAdmin(address caller) public {
        vm.assume(caller != admin);
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(0xAAAA), supplyBps: 10_000, borrowBps: 0});
        vm.prank(caller);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setWeights(ws);
    }

    /// @dev Transferring admin to any non-zero address must authorize that address and nobody else.
    function testFuzz_SetAdmin_TransfersExclusively(address newAdmin) public {
        vm.assume(newAdmin != address(0) && newAdmin != admin);

        vm.prank(admin);
        cfg.setAdmin(newAdmin);
        assertEq(cfg.admin(), newAdmin);

        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(0xAAAA), supplyBps: 10_000, borrowBps: 0});

        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setWeights(ws);

        vm.prank(newAdmin);
        cfg.setWeights(ws);
    }
}
