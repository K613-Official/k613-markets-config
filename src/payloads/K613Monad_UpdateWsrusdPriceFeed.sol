// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {K613PayloadMonad} from "./K613PayloadMonad.sol";
import {IAaveV3ConfigEngine} from "lib/K613-Protocol/src/contracts/extensions/v3-config-engine/IAaveV3ConfigEngine.sol";

contract K613Monad_UpdateWsrusdPriceFeed is K613PayloadMonad {
    address internal constant WSRUSD = 0x4809010926aec940b550D34a46A52739f996D75D;
    address internal constant NEW_WSRUSD_PRICE_FEED = 0x1111111111111111111111111111111111111111;

    function priceFeedsUpdates() public view override returns (IAaveV3ConfigEngine.PriceFeedUpdate[] memory updates) {
        updates = new IAaveV3ConfigEngine.PriceFeedUpdate[](1);
        updates[0] = IAaveV3ConfigEngine.PriceFeedUpdate({asset: WSRUSD, priceFeed: NEW_WSRUSD_PRICE_FEED});
    }
}
