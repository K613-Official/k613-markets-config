// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {K613Monad_UpdateWsrusdPriceFeed} from "../src/payloads/K613Monad_UpdateWsrusdPriceFeed.sol";
import {IAaveV3ConfigEngine} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol";

contract K613Monad_UpdateWsrusdPriceFeedTest is Test {
    address internal constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    address internal constant NEW_FEED = 0x1111111111111111111111111111111111111111;

    function test_PriceFeedUpdateContainsOnlyWsrusd() public {
        K613Monad_UpdateWsrusdPriceFeed payload = new K613Monad_UpdateWsrusdPriceFeed();
        IAaveV3ConfigEngine.PriceFeedUpdate[] memory updates = payload.priceFeedsUpdates();

        assertEq(updates.length, 1);
        assertEq(updates[0].asset, WSRUSD);
        assertEq(updates[0].priceFeed, NEW_FEED);
    }
}
