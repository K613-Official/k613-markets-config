// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IACLManager} from "lib/K613-Protocol/src/contracts/interfaces/IACLManager.sol";
import {K613PayloadMonad} from "../../src/payloads/K613PayloadMonad.sol";
import {K613Monad_InitialListing} from "../../src/payloads/K613Monad_InitialListing.sol";
import {K613Monad_ConfigureEModes} from "../../src/payloads/K613Monad_ConfigureEModes.sol";
import {MonadMainnet} from "../../src/networks/MonadMainnet.sol";

/// @title ExecutePayload
/// @notice Deploys and executes a config-engine payload via temporary POOL_ADMIN grant.
/// @dev AaveV3Payload.execute() uses functionDelegateCall to CONFIG_ENGINE, so external
///      calls to PoolConfigurator have msg.sender = payload contract address.
///      Without POOL_ADMIN on the payload, those calls revert with ACL errors.
///      The script grants POOL_ADMIN before execute() and revokes it after.
contract ExecutePayload is Script {
    error UnknownPayload(string name);

    function run() external {
        string memory name = vm.envString("PAYLOAD");

        vm.startBroadcast();

        K613PayloadMonad payload;
        bytes32 h = keccak256(bytes(name));
        if (h == keccak256("InitialListing")) {
            payload = new K613Monad_InitialListing();
        } else if (h == keccak256("ConfigureEModes")) {
            payload = new K613Monad_ConfigureEModes();
        } else {
            revert UnknownPayload(name);
        }

        console.log("Payload:", name);
        console.log("Deployed at:", address(payload));

        IACLManager acl = IACLManager(MonadMainnet.ACL_MANAGER);

        acl.addPoolAdmin(address(payload));
        console.log("Temporary POOL_ADMIN granted to payload");

        payload.execute();
        console.log("Executed.");

        acl.removePoolAdmin(address(payload));
        console.log("POOL_ADMIN revoked from payload");

        vm.stopBroadcast();
    }
}
