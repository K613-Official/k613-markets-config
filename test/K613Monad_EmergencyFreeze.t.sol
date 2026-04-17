// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {MonadMainnet} from "../src/networks/MonadMainnet.sol";

/// @title K613Monad_EmergencyFreezeTest
/// @notice Verifies direct `PoolConfigurator.setReserveFreeze` calls as the broadcaster would.
///         The script no longer deploys an intermediate payload contract — it calls the
///         configurator directly so `msg.sender` holds the ACL role.
contract K613Monad_EmergencyFreezeTest is Test {
    address internal constant ASSET = address(0xBEEF);

    function test_FreezeCallsConfiguratorDirectly() public {
        vm.mockCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, true),
            ""
        );
        vm.expectCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, true)
        );
        IPoolConfigurator(MonadMainnet.POOL_CONFIGURATOR).setReserveFreeze(ASSET, true);
    }

    function test_UnfreezeCallsConfiguratorDirectly() public {
        vm.mockCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, false),
            ""
        );
        vm.expectCall(
            MonadMainnet.POOL_CONFIGURATOR,
            abi.encodeWithSelector(IPoolConfigurator.setReserveFreeze.selector, ASSET, false)
        );
        IPoolConfigurator(MonadMainnet.POOL_CONFIGURATOR).setReserveFreeze(ASSET, false);
    }
}
