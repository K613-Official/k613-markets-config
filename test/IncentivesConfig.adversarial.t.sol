// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {IncentivesConfig} from "../src/incentives/IncentivesConfig.sol";

/// @title IncentivesConfigAdversarialTest
/// @notice Tries to break IncentivesConfig: admin escalation, uint88 truncation, state corruption.
contract IncentivesConfigAdversarialTest is Test {
    IncentivesConfig internal cfg;
    address internal admin = address(0xA11CE);
    address internal attacker = address(0xDEAD);

    function setUp() public {
        cfg = new IncentivesConfig(admin);
    }

    // ───────── Admin privilege escalation ─────────

    /// @dev After admin transfer, OLD admin must be locked out permanently.
    function test_OldAdminLockedOutAfterTransfer() public {
        vm.prank(admin);
        cfg.setAdmin(attacker);

        // Old admin tries everything
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 6000, borrowBps: 4000});

        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setWeights(ws);

        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setAdmin(admin); // try to steal back
    }

    /// @dev Admin transfers to self — should work, no state change.
    function test_AdminTransferToSelf() public {
        vm.prank(admin);
        cfg.setAdmin(admin);
        assertEq(cfg.admin(), admin);
    }

    /// @dev Chain of transfers: A → B → C. Only C should have access.
    function test_AdminTransferChain() public {
        address b = address(0xBBBB);
        address c = address(0xCCCC);

        vm.prank(admin);
        cfg.setAdmin(b);

        vm.prank(b);
        cfg.setAdmin(c);

        // Only C can act
        vm.prank(admin);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setAdmin(admin);

        vm.prank(b);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setAdmin(b);

        // C succeeds
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 6000, borrowBps: 4000});
        vm.prank(c);
        cfg.setWeights(ws);
        assertEq(cfg.weightCount(), 1);
    }

    /// @dev Random address cannot call setWeights.
    function testFuzz_RandomAddressCannotSetWeights(address who) public {
        vm.assume(who != admin);
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 6000, borrowBps: 4000});

        vm.prank(who);
        vm.expectRevert(IncentivesConfig.Unauthorized.selector);
        cfg.setWeights(ws);
    }

    // ───────── uint88 truncation boundary ─────────

    /// @dev uint88 max = 309_485_009_821_345_068_724_781_055.
    ///      If yearlyTotal is huge, supplyYearly / 365 days can exceed uint88 → silent truncation.
    function test_Uint88Truncation_SilentDataLoss() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 10_000, borrowBps: 0});
        vm.prank(admin);
        cfg.setWeights(ws);

        // uint88 max ≈ 3.09e26. yearlyTotal where yearly / 365 days > uint88 max:
        // yearly / 31_536_000 > 3.09e26 → yearly > 9.76e33
        uint256 hugeYearly = 1e34;
        IncentivesConfig.EmissionConfig[] memory configs = cfg.getEmissionConfigs(hugeYearly);

        uint256 expected = hugeYearly / 365 days;
        uint256 actual = uint256(configs[0].supplyEmissionPerSecond);

        // If truncation happens, actual != expected
        if (expected > type(uint88).max) {
            // Truncated — this is the bug: silent data loss
            assertTrue(actual != expected, "should have been truncated");
            assertTrue(actual < expected, "truncation should reduce value");
        }
    }

    /// @dev With real YEAR1_TOTAL, no truncation should occur.
    function test_NoTruncation_WithRealYearlyTotal() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 10_000, borrowBps: 0});
        vm.prank(admin);
        cfg.setWeights(ws);

        uint256 yearly = cfg.YEAR1_TOTAL(); // 25_000_000e18
        IncentivesConfig.EmissionConfig[] memory configs = cfg.getEmissionConfigs(yearly);

        uint256 expected = yearly / 365 days;
        uint256 actual = uint256(configs[0].supplyEmissionPerSecond);
        assertEq(actual, expected, "real yearly total must not truncate");
        assertLt(expected, uint256(type(uint88).max), "expected fits in uint88");
    }

    // ───────── Weight manipulation attacks ─────────

    /// @dev Set weights with bps values that individually overflow uint256 sum? No — Solidity ^0.8.
    function test_WeightBpsOverflow_Reverts() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](2);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: type(uint256).max, borrowBps: 0});
        ws[1] = IncentivesConfig.AssetWeight({asset: address(2), supplyBps: 1, borrowBps: 0});

        vm.prank(admin);
        vm.expectRevert(); // overflow on sum
        cfg.setWeights(ws);
    }

    /// @dev supplyBps = 0, borrowBps = 0 for an asset — zero-weight parasite takes a slot.
    function test_ZeroWeightAsset_StillCountsInSum() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](2);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 0, borrowBps: 0});
        ws[1] = IncentivesConfig.AssetWeight({asset: address(2), supplyBps: 6000, borrowBps: 4000});
        vm.prank(admin);
        cfg.setWeights(ws);

        // Asset 1 has zero emissions but occupies a slot
        IncentivesConfig.EmissionConfig[] memory configs = cfg.getEmissionConfigs(cfg.YEAR1_TOTAL());
        assertEq(configs.length, 2);
        assertEq(uint256(configs[0].supplyEmissionPerSecond), 0);
        assertEq(uint256(configs[0].borrowEmissionPerSecond), 0);
    }

    /// @dev setWeights replaces atomically — old data fully gone.
    function test_SetWeights_OldDataFullyPurged() public {
        IncentivesConfig.AssetWeight[] memory ws1 = new IncentivesConfig.AssetWeight[](3);
        ws1[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 3000, borrowBps: 1000});
        ws1[1] = IncentivesConfig.AssetWeight({asset: address(2), supplyBps: 2000, borrowBps: 1000});
        ws1[2] = IncentivesConfig.AssetWeight({asset: address(3), supplyBps: 1500, borrowBps: 1500});
        vm.prank(admin);
        cfg.setWeights(ws1);
        assertEq(cfg.weightCount(), 3);

        // Replace with 1 asset
        IncentivesConfig.AssetWeight[] memory ws2 = new IncentivesConfig.AssetWeight[](1);
        ws2[0] = IncentivesConfig.AssetWeight({asset: address(9), supplyBps: 7000, borrowBps: 3000});
        vm.prank(admin);
        cfg.setWeights(ws2);

        assertEq(cfg.weightCount(), 1);
        IncentivesConfig.AssetWeight[] memory stored = cfg.getWeights();
        assertEq(stored[0].asset, address(9));
        // Old assets completely gone
    }

    // ───────── getEmissionConfigs with zero yearly ─────────

    /// @dev yearlyTotal = 0 → all emissions zero. Should not revert.
    function test_ZeroYearlyTotal_AllZeroEmissions() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 6000, borrowBps: 4000});
        vm.prank(admin);
        cfg.setWeights(ws);

        IncentivesConfig.EmissionConfig[] memory configs = cfg.getEmissionConfigs(0);
        assertEq(uint256(configs[0].supplyEmissionPerSecond), 0);
        assertEq(uint256(configs[0].borrowEmissionPerSecond), 0);
    }

    // ───────── getEmissionConfigs precision loss ─────────

    /// @dev Small yearlyTotal with high weight → rounds to zero due to integer division.
    function test_SmallYearly_PrecisionLoss() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 1, borrowBps: 9999});
        vm.prank(admin);
        cfg.setWeights(ws);

        // yearlyTotal = 1e18 (1 token). supplyBps = 1 → supplyYearly = 1e18 * 1 / 10000 = 1e14
        // supplyEmission = 1e14 / 31_536_000 = 3_170_979 ≈ 3.17e6 → rounds down
        uint256 yearly = 1e18;
        IncentivesConfig.EmissionConfig[] memory configs = cfg.getEmissionConfigs(yearly);
        uint256 supplyPerSec = uint256(configs[0].supplyEmissionPerSecond);

        // Verify: reconstructed yearly from per-sec must be <= original
        uint256 reconstructed = supplyPerSec * 365 days * 10_000 / 1;
        assertLe(reconstructed, yearly, "reconstructed must not exceed original");
    }

    // ───────── Event emission ─────────

    /// @dev Verify WeightsUpdated event is emitted on setWeights.
    function test_WeightsUpdated_EventEmitted() public {
        IncentivesConfig.AssetWeight[] memory ws = new IncentivesConfig.AssetWeight[](1);
        ws[0] = IncentivesConfig.AssetWeight({asset: address(1), supplyBps: 6000, borrowBps: 4000});

        vm.prank(admin);
        vm.expectEmit(false, false, false, false);
        emit IncentivesConfig.WeightsUpdated(ws);
        cfg.setWeights(ws);
    }

    /// @dev Verify AdminUpdated event on setAdmin.
    function test_AdminUpdated_EventEmitted() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, false);
        emit IncentivesConfig.AdminUpdated(admin, attacker);
        cfg.setAdmin(attacker);
    }
}
