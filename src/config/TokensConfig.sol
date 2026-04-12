// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title TokensConfig
/// @notice Network-specific token definitions for reserve listing and oracle wiring.
/// @dev Token lists are static; extend `Network` and branch functions when adding deployments.
library TokensConfig {
    /// @notice Deployments covered by this configuration.
    enum Network {
        ArbitrumSepolia,
        MonadMainnet
    }

    /// @notice Metadata for a single underlying asset and its price feed.
    struct Token {
        /// @notice Underlying ERC20 asset address.
        address asset;
        /// @notice Chainlink-style aggregator or oracle source registered on the Aave oracle.
        address priceFeed;
        /// @notice ERC20 decimals of the underlying asset.
        uint8 decimals;
        /// @notice Human-readable ticker used in aToken / debt token naming.
        string symbol;
    }

    /// @notice Returns the static token list for the given network.
    /// @param network Target chain deployment.
    /// @return tokens Configured assets in reserve listing order.
    function getTokens(Network network) internal pure returns (Token[] memory tokens) {
        if (network == Network.ArbitrumSepolia) {
            return _getArbitrumSepoliaTokens();
        } else if (network == Network.MonadMainnet) {
            return _getMonadMainnetTokens();
        } else {
            revert("Unsupported network");
        }
    }

    /// @notice Internal token table for Arbitrum Sepolia.
    /// @return tokens Fixed-size array of testnet assets.
    function _getArbitrumSepoliaTokens() private pure returns (Token[] memory tokens) {
        tokens = new Token[](5);

        // WETH - Wrapped Ether
        tokens[0] = Token({
            asset: 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73, // WETH Arbitrum Sepolia
            priceFeed: 0x2d3bBa5e0A9Fd8EAa45Dcf71A2389b7C12005b1f, // ETH/USD Sepolia
            decimals: 18,
            symbol: "WETH"
        });

        // USDC - USD Coin
        tokens[1] = Token({
            asset: 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d,
            priceFeed: 0x0153002d20B96532C639313c2d54c3dA09109309, // USDC/USD Sepolia
            decimals: 6,
            symbol: "USDC"
        });

        // USDT - Tether
        tokens[2] = Token({
            asset: 0x30fA2FbE15c1EaDfbEF28C188b7B8dbd3c1Ff2eB, // USDT Arbitrum Sepolia
            priceFeed: 0x80EDee6f667eCc9f63a0a6f55578F870651f06A4, // USDT/USD Sepolia
            decimals: 6,
            symbol: "USDT"
        });

        // DAI - Dai Stablecoin
        tokens[3] = Token({
            asset: 0xbC47901f4d2C5fc871ae0037Ea05c3F614690781, // DAI Arbitrum Sepolia
            priceFeed: 0xb113F5A928BCfF189C998ab20d753a47F9dE5A61, // DAI/USD Sepolia
            decimals: 18,
            symbol: "DAI"
        });

        // BTC - Wrapped Bitcoin
        tokens[4] = Token({
            asset: 0x152B0DF80135c63B4Cb1FBE00DDCE7E9a8FFCb04, // BTC Arbitrum Sepolia
            priceFeed: 0x56a43EB56Da12C0dc1D972ACb089c06a5dEF8e69, // BTC/USD Arbitrum Sepolia
            decimals: 8,
            symbol: "BTC"
        });
    }

    /// @notice Internal token table for Monad mainnet.
    /// @return tokens Fixed-size array of production assets.
    function _getMonadMainnetTokens() private pure returns (Token[] memory tokens) {
        tokens = new Token[](11);

        // USDC - USD Coin
        tokens[0] = Token({
            asset: 0x754704Bc059F8C67012fEd69BC8A327a5aafb603,
            priceFeed: 0xf5F15f188AbCB0d165D1Edb7f37F7d6fA2fCebec,
            decimals: 6,
            symbol: "USDC"
        });

        // AUSD - Agora USD
        tokens[1] = Token({
            asset: 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a,
            priceFeed: 0xE20751C7B5867bCBef815ffc1b284c3f412a9e13,
            decimals: 18,
            symbol: "AUSD"
        });

        // wstETH - Wrapped Staked Ether
        tokens[2] = Token({
            asset: 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417,
            priceFeed: 0xe6cd21b31948503dB54A07875999979722504B9A, 
            decimals: 18,
            symbol: "wstETH"
        });

        // WETH - Wrapped Ether
        tokens[3] = Token({
            asset: 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242,
            priceFeed: 0x1B1414782B859871781bA3E4B0979b9ca57A0A04,
            decimals: 18,
            symbol: "WETH"
        });

        // USDT0 - Tether (LayerZero)
        tokens[4] = Token({
            asset: 0xe7cd86e13AC4309349F30B3435a9d337750fC82D,
            priceFeed: 0x1a1Be4c184923a6BFF8c27cfDf6ac8bDE4DE00FC,
            decimals: 6,
            symbol: "USDT0"
        });

        // WSRUSD - Wrapped srUSD
        tokens[5] = Token({
            asset: 0x4809010926aec940b550D34a46A52739f996D75D,
            priceFeed: 0x99bb13E956ba6e25624cAe95A41ED705AeA2557d,
            decimals: 18,
            symbol: "WSRUSD"
        });

        // WBTC - Wrapped Bitcoin
        tokens[6] = Token({
            asset: 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c,
            priceFeed: 0x2D1Df1bD061AAc38C22407AD69d69bCC3C62edBD, 
            decimals: 8,
            symbol: "WBTC"
        });

        // WMON - Wrapped MON
        tokens[7] = Token({
            asset: 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A,
            priceFeed: 0xBcD78f76005B7515837af6b50c7C52BCf73822fb,
            decimals: 18,
            symbol: "WMON"
        });

        // SHMON 
        tokens[8] = Token({
            asset: 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c,
            priceFeed: 0x4f9ba5CaE0e3F651821283EC4e303fE8D1dA542a,
            decimals: 18,
            symbol: "SHMON"
        });

        // SMON
        tokens[9] = Token({
            asset: 0xA3227C5969757783154C60bF0bC1944180ed81B9,
            priceFeed: 0x80Efb6394E142F778cdD7F59b6Ee484B5a6299EB,
            decimals: 18,
            symbol: "SMON"
        });

        // GMON 
        tokens[10] = Token({
            asset: 0x8498312A6B3CbD158bf0c93AbdCF29E6e4F55081,
            priceFeed: 0xE53969561603a9052E3F579b2992C12F3C783496,
            decimals: 18,
            symbol: "GMON"
        });
    }
}
