// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title AdminOps
/// @notice Single-action admin script for routine PoolConfigurator ops — no one-shot payload needed.
/// @dev Caller must already hold the relevant role (POOL_ADMIN / RISK_ADMIN) via ACLManager.
///      Env vars:
///        ADMIN_OP    — one of: supplyCap | borrowCap | reserveFactor | liqProtocolFee
///        ADMIN_ASSET — underlying asset address
///        ADMIN_VALUE — uint256 parameter (caps in whole units, factors in bps)
contract AdminOps is Script {
    /// @notice `ADMIN_OP` did not match a supported operation name.
    error UnknownOp(string op);

    /// @notice Dispatches a single `ADMIN_OP` against `PoolConfigurator` on Monad mainnet.
    function run() external {
        string memory op = vm.envString("ADMIN_OP");
        address asset = vm.envAddress("ADMIN_ASSET");
        uint256 value = vm.envUint("ADMIN_VALUE");

        IPoolConfigurator cfg = IPoolConfigurator(MonadMainnet.POOL_CONFIGURATOR);

        vm.startBroadcast();

        bytes32 h = keccak256(bytes(op));
        if (h == keccak256("supplyCap")) {
            cfg.setSupplyCap(asset, value);
            console.log("setSupplyCap", asset, value);
        } else if (h == keccak256("borrowCap")) {
            cfg.setBorrowCap(asset, value);
            console.log("setBorrowCap", asset, value);
        } else if (h == keccak256("reserveFactor")) {
            cfg.setReserveFactor(asset, value);
            console.log("setReserveFactor", asset, value);
        } else if (h == keccak256("liqProtocolFee")) {
            cfg.setLiquidationProtocolFee(asset, value);
            console.log("setLiquidationProtocolFee", asset, value);
        } else {
            revert UnknownOp(op);
        }

        vm.stopBroadcast();
    }
}
