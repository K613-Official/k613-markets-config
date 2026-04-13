// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {TokensConfig} from "../src/config/TokensConfig.sol";
import {TokensRegistry} from "../src/config/TokensRegistry.sol";
import {ITokensRegistry} from "../src/config/interface/ITokensRegistry.sol";

contract TokensConfigTest is Test {
    ITokensRegistry internal registry;

    function setUp() public {
        registry = ITokensRegistry(address(new TokensRegistry(address(this))));
    }

    function test_GetArbitrumSepoliaTokens() public view {
        TokensConfig.Token[] memory tokens = registry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        assertEq(tokens.length, 5, "Should have 5 tokens");

        assertEq(tokens[0].symbol, "WETH", "First token should be WETH");
        assertEq(tokens[0].decimals, 18, "WETH should have 18 decimals");
        assertEq(tokens[0].asset, 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73, "WETH address should match");

        assertEq(tokens[1].symbol, "USDC", "Second token should be USDC");
        assertEq(tokens[1].decimals, 6, "USDC should have 6 decimals");
        assertEq(tokens[1].asset, 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d, "USDC address should match");

        assertEq(tokens[2].symbol, "USDT", "Third token should be USDT");
        assertEq(tokens[2].decimals, 6, "USDT should have 6 decimals");

        assertEq(tokens[3].symbol, "DAI", "Fourth token should be DAI");
        assertEq(tokens[3].decimals, 18, "DAI should have 18 decimals");

        assertEq(tokens[4].symbol, "BTC", "Fifth token should be BTC");
        assertEq(tokens[4].decimals, 8, "BTC should have 8 decimals");
    }

    function test_GetMonadMainnetTokens() public view {
        TokensConfig.Token[] memory tokens = registry.getTokens(TokensConfig.Network.MonadMainnet);

        assertEq(tokens.length, 11, "Should have 11 tokens");

        assertEq(tokens[0].symbol, "USDC");
        assertEq(tokens[0].asset, 0x754704Bc059F8C67012fEd69BC8A327a5aafb603);
        assertEq(tokens[0].decimals, 6);

        assertEq(tokens[1].symbol, "AUSD");
        assertEq(tokens[1].asset, 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a);
        assertEq(tokens[1].decimals, 18);

        assertEq(tokens[2].symbol, "wstETH");
        assertEq(tokens[2].asset, 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417);
        assertEq(tokens[2].decimals, 18);

        assertEq(tokens[3].symbol, "WETH");
        assertEq(tokens[3].asset, 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242);
        assertEq(tokens[3].decimals, 18);

        assertEq(tokens[4].symbol, "USDT0");
        assertEq(tokens[4].asset, 0xe7cd86e13AC4309349F30B3435a9d337750fC82D);
        assertEq(tokens[4].decimals, 6);

        assertEq(tokens[5].symbol, "WSRUSD");
        assertEq(tokens[5].asset, 0x4809010926aec940b550D34a46A52739f996D75D);
        assertEq(tokens[5].decimals, 18);

        assertEq(tokens[6].symbol, "WBTC");
        assertEq(tokens[6].asset, 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c);
        assertEq(tokens[6].decimals, 8);

        assertEq(tokens[7].symbol, "WMON");
        assertEq(tokens[7].asset, 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A);
        assertEq(tokens[7].decimals, 18);

        assertEq(tokens[8].symbol, "SHMON");
        assertEq(tokens[8].asset, 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c);
        assertEq(tokens[8].decimals, 18);

        assertEq(tokens[9].symbol, "SMON");
        assertEq(tokens[9].asset, 0xA3227C5969757783154C60bF0bC1944180ed81B9);
        assertEq(tokens[9].decimals, 18);

        assertEq(tokens[10].symbol, "GMON");
        assertEq(tokens[10].asset, 0x8498312A6B3CbD158bf0c93AbdCF29E6e4F55081);
        assertEq(tokens[10].decimals, 18);
    }

    function test_UnsupportedNetwork() public view {
        TokensConfig.Token[] memory tokens = registry.getTokens(TokensConfig.Network.ArbitrumSepolia);
        assertGt(tokens.length, 0, "ArbitrumSepolia should return tokens");
    }

    function test_TokenStructure() public view {
        TokensConfig.Token[] memory tokens = registry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        for (uint256 i = 0; i < tokens.length; i++) {
            assertNotEq(tokens[i].asset, address(0), "Asset address should not be zero");
            assertNotEq(tokens[i].priceFeed, address(0), "Price feed should not be zero");
            assertGt(tokens[i].decimals, 0, "Decimals should be greater than 0");
            assertLe(tokens[i].decimals, 18, "Decimals should not exceed 18");
            assertGt(bytes(tokens[i].symbol).length, 0, "Symbol should not be empty");
        }
    }

    function test_AllTokensHaveValidDecimals() public view {
        TokensConfig.Token[] memory tokens = registry.getTokens(TokensConfig.Network.ArbitrumSepolia);

        uint8[5] memory expectedDecimals = [uint8(18), 6, 6, 18, 8];
        string[5] memory symbols = ["WETH", "USDC", "USDT", "DAI", "BTC"];

        for (uint256 i = 0; i < tokens.length; i++) {
            assertEq(tokens[i].decimals, expectedDecimals[i], string.concat("Decimals mismatch for ", symbols[i]));
        }
    }
}
