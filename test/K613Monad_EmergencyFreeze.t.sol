// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {K613Monad_EmergencyFreeze} from "../src/payloads/emergency/K613Monad_EmergencyFreeze.sol";
import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {MonadMainnet} from "../src/config/networks/MonadMainnet.sol";

/// @title K613Monad_EmergencyFreezeTest
/// @notice Tests freeze payload storage and the calldata sent to `PoolConfigurator`.
contract K613Monad_EmergencyFreezeTest is Test {
    address internal constant ASSET = address(0xBEEF);

    function test_StoresConstructorArgs() public {
        K613Monad_EmergencyFreeze p = new K613Monad_EmergencyFreeze(ASSET, true);
        assertEq(p.asset(), ASSET);
        assertTrue(p.freeze());
    }

    function test_ExecuteCallsSetReserveFreeze_true() public {
        K613Monad_EmergencyFreeze p = new K613Monad_EmergencyFreeze(ASSET, true);
        vm.mockCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, true),
            ""
        );
        vm.expectCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, true)
        );
        p.execute();
    }

    function test_ExecuteCallsSetReserveFreeze_false() public {
        K613Monad_EmergencyFreeze p = new K613Monad_EmergencyFreeze(ASSET, false);
        vm.mockCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, false),
            ""
        );
        vm.expectCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, false)
        );
        p.execute();
    }
}
