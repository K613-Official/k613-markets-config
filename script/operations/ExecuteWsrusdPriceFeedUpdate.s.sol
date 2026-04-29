// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {IACLManager} from "lib/K613-Protocol/src/contracts/interfaces/IACLManager.sol";
import {K613Monad_UpdateWsrusdPriceFeed} from "../../src/payloads/K613Monad_UpdateWsrusdPriceFeed.sol";
import {MonadMainnet} from "../../src/networks/MonadMainnet.sol";

contract ExecuteWsrusdPriceFeedUpdate is Script {
    function run() external {
        vm.startBroadcast();

        K613Monad_UpdateWsrusdPriceFeed payload = new K613Monad_UpdateWsrusdPriceFeed();
        console.log("Payload:", address(payload));

        IACLManager acl = IACLManager(MonadMainnet.ACL_MANAGER);
        acl.addPoolAdmin(address(payload));
        payload.execute();
        acl.removePoolAdmin(address(payload));

        vm.stopBroadcast();
    }
}
