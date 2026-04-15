// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {K613Monad_EmergencyPause} from "../src/payloads/emergency/K613Monad_EmergencyPause.sol";
import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {MonadMainnet} from "../src/networks/MonadMainnet.sol";

/// @title K613Monad_EmergencyPauseTest
/// @notice Tests pause payload storage and the calldata sent to `PoolConfigurator`.
contract K613Monad_EmergencyPauseTest is Test {
    address internal constant ASSET = address(0xBEEF);

    bytes4 internal constant SET_RESERVE_PAUSE_2ARG = bytes4(keccak256("setReservePause(address,bool)"));

    function test_StoresConstructorArgs() public {
        K613Monad_EmergencyPause p = new K613Monad_EmergencyPause(ASSET, true);
        assertEq(p.asset(), ASSET);
        assertTrue(p.paused());
    }

    function test_ExecuteCallsSetReservePause_true() public {
        K613Monad_EmergencyPause p = new K613Monad_EmergencyPause(ASSET, true);
        vm.mockCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, true), "");
        vm.expectCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, true));
        p.execute();
    }

    function test_ExecuteCallsSetReservePause_false() public {
        K613Monad_EmergencyPause p = new K613Monad_EmergencyPause(ASSET, false);
        vm.mockCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, false), "");
        vm.expectCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, false));
        p.execute();
    }
}
