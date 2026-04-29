// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ExchangeRateAdapter} from "../../src/adapters/ExchangeRateAdapter.sol";

contract DeployAdapters is Script {
    // address internal constant MON_USD = 0xBcD78f76005B7515837af6b50c7C52BCf73822fb;
    // address internal constant SHMON_MON = 0x54a1020D118B9BeF3F3A4ec8E24AeEc9DFdBe4c3;
    // address internal constant SMON_MON = 0x056d0eF95A4e046D028b00E6eC00bB4A8b1eBb96;
    // address internal constant GMON_MON = 0xf97dfEd6Aa4cc387aBC5d47F0062A91CB4E4A755;
    address internal constant WSRUSD_RUSD = 0x99bb13E956ba6e25624cAe95A41ED705AeA2557d;
    address internal constant USDS_USD = 0xa16212CD5b330583B346167fA91E138d41AEe8CC;

    function run() external {
        vm.startBroadcast();

        console.log("Deploying ExchangeRateAdapter...\n");

        // ExchangeRateAdapter shmonAdapter = new ExchangeRateAdapter(SHMON_MON, MON_USD, "shMON / USD");
        // console.log("shMON/USD adapter:", address(shmonAdapter));
        // ExchangeRateAdapter smonAdapter = new ExchangeRateAdapter(SMON_MON, MON_USD, "sMON / USD");
        // console.log("sMON/USD adapter:", address(smonAdapter));
        // ExchangeRateAdapter gmonAdapter = new ExchangeRateAdapter(GMON_MON, MON_USD, "gMON / USD");
        // console.log("gMON/USD adapter:", address(gmonAdapter));

        ExchangeRateAdapter wsrusdAdapter = new ExchangeRateAdapter(WSRUSD_RUSD, USDS_USD, "WSRUSD / USD");
        console.log("WSRUSD/USD adapter:", address(wsrusdAdapter));

        vm.stopBroadcast();

        console.log("\n=== Update payload priceFeed address ===");
        // console.log("SHMON priceFeed:", address(shmonAdapter));
        // console.log("SMON  priceFeed:", address(smonAdapter));
        // console.log("GMON  priceFeed:", address(gmonAdapter));
        console.log("WSRUSD priceFeed:", address(wsrusdAdapter));
    }
}
