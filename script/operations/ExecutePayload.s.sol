// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {K613PayloadMonad} from "../../src/payloads/K613PayloadMonad.sol";
import {K613Monad_InitialListing} from "../../src/payloads/K613Monad_InitialListing.sol";
import {K613Monad_ConfigureEModes} from "../../src/payloads/K613Monad_ConfigureEModes.sol";

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

        payload.execute();
        console.log("Executed.");

        vm.stopBroadcast();
    }
}
