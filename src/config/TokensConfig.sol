// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title TokensConfig
/// @notice Network-specific token configurations
library TokensConfig {
    enum Network {
        ArbitrumSepolia,
        MonadMainnet
    }

    struct Token {
        address asset;
        address priceFeed;
        uint8 decimals;
        string symbol;
    }

    /// @notice Gets tokens for a specific network
    /// @param network The network to get tokens for
    function getTokens(Network network) internal pure returns (Token[] memory tokens) {
        if (network == Network.ArbitrumSepolia) {
            return _getArbitrumSepoliaTokens();
        } else if (network == Network.MonadMainnet) {
            return _getMonadMainnetTokens();
        } else {
            revert("Unsupported network");
        }
    }

    /// @notice Gets tokens for Arbitrum Sepolia testnet
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
            asset: 0x179522635726710d7C8455c2e0A28f16e07E0D53, // USDC Arbitrum Sepolia
            priceFeed: 0x1692b46432CF26E6e5d6c14A6b22F31Dd4c54F82, // USDC/USD Sepolia
            decimals: 6,
            symbol: "USDC"
        });

        // USDT - Tether
        tokens[2] = Token({
            asset: 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7, // USDT Arbitrum Sepolia
            priceFeed: 0x0a023A3423D9b27a0Be48c768ccf2dD78777F624, // USDT/USD Sepolia
            decimals: 6,
            symbol: "USDT"
        });

        // DAI - Dai Stablecoin
        tokens[3] = Token({
            asset: 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1, // DAI Arbitrum Sepolia
            priceFeed: 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB, // DAI/USD Sepolia
            decimals: 18,
            symbol: "DAI"
        });

        // WBTC - Wrapped Bitcoin
        tokens[4] = Token({
            asset: 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f, // WBTC Arbitrum Sepolia
            priceFeed: 0x6ce185860a4963106506C203335A2910413708e9, // WBTC/USD Sepolia
            decimals: 8,
            symbol: "WBTC"
        });
    }

    /// @notice Gets tokens for Monad Mainnet
    /// @dev TODO: Fill in Monad mainnet addresses when deploying to mainnet
    function _getMonadMainnetTokens() private pure returns (Token[] memory tokens) {
        tokens = new Token[](5);

        // WETH - Wrapped Ether
        tokens[0] = Token({
            asset: address(0), // TODO: Set WETH Monad Mainnet address
            priceFeed: address(0), // TODO: Set ETH/USD Monad Mainnet price feed
            decimals: 18,
            symbol: "WETH"
        });

        // USDC - USD Coin
        tokens[1] = Token({
            asset: address(0), // TODO: Set USDC Monad Mainnet address
            priceFeed: address(0), // TODO: Set USDC/USD Monad Mainnet price feed
            decimals: 6,
            symbol: "USDC"
        });

        // USDT - Tether
        tokens[2] = Token({
            asset: address(0), // TODO: Set USDT Monad Mainnet address
            priceFeed: address(0), // TODO: Set USDT/USD Monad Mainnet price feed
            decimals: 6,
            symbol: "USDT"
        });

        // DAI - Dai Stablecoin
        tokens[3] = Token({
            asset: address(0), // TODO: Set DAI Monad Mainnet address
            priceFeed: address(0), // TODO: Set DAI/USD Monad Mainnet price feed
            decimals: 18,
            symbol: "DAI"
        });

        // WBTC - Wrapped Bitcoin
        tokens[4] = Token({
            asset: address(0), // TODO: Set WBTC Monad Mainnet address
            priceFeed: address(0), // TODO: Set WBTC/USD Monad Mainnet price feed
            decimals: 8,
            symbol: "WBTC"
        });
    }
}
