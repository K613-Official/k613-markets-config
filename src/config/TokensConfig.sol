// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

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
            priceFeed: 0x0153002d20B96532C639313c2d54c3dA09109309, // USDC/USD Sepolia
            decimals: 6,
            symbol: "USDC"
        });

        // USDT - Tether
        tokens[2] = Token({
            asset: 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7, // USDT Arbitrum Sepolia
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
