// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {IPoolConfigurator} from "lib/K613-Protocol/src/contracts/interfaces/IPoolConfigurator.sol";
import {MonadMainnet} from "../src/networks/MonadMainnet.sol";

/// @title K613Monad_EmergencyPauseTest
/// @notice Verifies direct `PoolConfigurator.setReservePause` calls as the broadcaster would.
contract K613Monad_EmergencyPauseTest is Test {
    address internal constant ASSET = address(0xBEEF);

    bytes4 internal constant SET_RESERVE_PAUSE_2ARG = bytes4(keccak256("setReservePause(address,bool)"));

    function test_PauseCallsConfiguratorDirectly() public {
        vm.mockCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, true), "");
        vm.expectCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, true));
        IPoolConfigurator(MonadMainnet.POOL_CONFIGURATOR).setReservePause(ASSET, true);
    }

    function test_UnpauseCallsConfiguratorDirectly() public {
        vm.mockCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, false), "");
        vm.expectCall(MonadMainnet.POOL_CONFIGURATOR, abi.encodeWithSelector(SET_RESERVE_PAUSE_2ARG, ASSET, false));
        IPoolConfigurator(MonadMainnet.POOL_CONFIGURATOR).setReservePause(ASSET, false);
    }
}
