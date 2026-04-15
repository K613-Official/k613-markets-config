// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ExchangeRateAdapter} from "../src/adapters/ExchangeRateAdapter.sol";

/// @title DeployAdapters
/// @notice Deploys `ExchangeRateAdapter` instances for SHMON, SMON, and GMON.
/// @dev After deployment, paste printed adapter addresses into listing payload `priceFeed` fields.
contract DeployAdapters is Script {
    /// @notice Chainlink MON/USD feed on Monad mainnet (second leg of each adapter).
    address internal constant MON_USD = 0xBcD78f76005B7515837af6b50c7C52BCf73822fb;

    /// @notice Chainlink shMON/MON exchange rate feed on Monad mainnet.
    address internal constant SHMON_MON = 0x54a1020D118B9BeF3F3A4ec8E24AeEc9DFdBe4c3;
    /// @notice Chainlink sMON/MON exchange rate feed on Monad mainnet.
    address internal constant SMON_MON = 0x056d0eF95A4e046D028b00E6eC00bB4A8b1eBb96;
    /// @notice Chainlink gMON/MON exchange rate feed on Monad mainnet.
    address internal constant GMON_MON = 0xf97dfEd6Aa4cc387aBC5d47F0062A91CB4E4A755;

    /// @notice Deploys three `ExchangeRateAdapter` contracts and logs their addresses.
    function run() external {
        vm.startBroadcast();

        console.log("Deploying ExchangeRateAdapters...\n");

        ExchangeRateAdapter shmonAdapter = new ExchangeRateAdapter(SHMON_MON, MON_USD, "shMON / USD");
        console.log("shMON/USD adapter:", address(shmonAdapter));

        ExchangeRateAdapter smonAdapter = new ExchangeRateAdapter(SMON_MON, MON_USD, "sMON / USD");
        console.log("sMON/USD adapter:", address(smonAdapter));

        ExchangeRateAdapter gmonAdapter = new ExchangeRateAdapter(GMON_MON, MON_USD, "gMON / USD");
        console.log("gMON/USD adapter:", address(gmonAdapter));

        vm.stopBroadcast();

        console.log("\n=== Update TokensConfig.sol priceFeed addresses ===");
        console.log("SHMON priceFeed:", address(shmonAdapter));
        console.log("SMON  priceFeed:", address(smonAdapter));
        console.log("GMON  priceFeed:", address(gmonAdapter));
    }
}
