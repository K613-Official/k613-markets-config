// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title TokensConfig
/// @notice Configuration for tokens to be listed on Aave v3
/// @dev Contains token addresses, symbols, price feeds, and decimals for Arbitrum testnet
contract TokensConfig {
    /// @notice Token configuration structure
    struct TokenConfig {
        address asset; // Token contract address
        string symbol; // Token symbol (e.g., "WETH", "USDC")
        address priceFeed; // Chainlink price feed address
        uint8 decimals; // Token decimals
    }

    /// @notice Array of token configurations for Arbitrum testnet
    /// @dev Tokens: WETH, USDC, USDT, DAI, WBTC
    TokenConfig[] public tokens;

    /// @notice Mapping from asset address to token config index
    mapping(address => uint256) public tokenIndex;

    /// @notice Mapping from asset address to token config
    mapping(address => TokenConfig) public tokenConfigs;

    constructor() {
        // WETH - Wrapped Ether
        _addToken(
            0x980B62Da83eFf3D4576C647993b0c1D7faf17c73, // WETH testnet address (placeholder)
            "WETH",
            0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08, // Chainlink WETH/USD feed (placeholder)
            18
        );

        // USDC - USD Coin
        _addToken(
            0x179522635726710d7C8455c2e0A28f16e07E0D53, // USDC testnet address (placeholder)
            "USDC",
            0x1692b46432CF26E6e5d6c14A6b22F31Dd4c54F82, // Chainlink USDC/USD feed (placeholder)
            6
        );

        // USDT - Tether
        _addToken(
            0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7, // USDT testnet address (placeholder)
            "USDT",
            0x0a023A3423D9b27a0Be48c768ccf2dD78777F624, // Chainlink USDT/USD feed (placeholder)
            6
        );

        // DAI - Dai Stablecoin
        _addToken(
            0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1, // DAI testnet address (placeholder)
            "DAI",
            0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB, // Chainlink DAI/USD feed (placeholder)
            18
        );

        // WBTC - Wrapped Bitcoin
        _addToken(
            0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f, // WBTC testnet address (placeholder)
            "WBTC",
            0x6ce185860a4963106506C203335A2910413708e9, // Chainlink WBTC/USD feed (placeholder)
            8
        );
    }

    /// @notice Internal function to add a token configuration
    /// @param asset Token contract address
    /// @param symbol Token symbol
    /// @param priceFeed Chainlink price feed address
    /// @param decimals Token decimals
    function _addToken(address asset, string memory symbol, address priceFeed, uint8 decimals) internal {
        require(asset != address(0), "Invalid asset address");
        require(priceFeed != address(0), "Invalid price feed address");
        require(bytes(symbol).length > 0, "Invalid symbol");

        TokenConfig memory config =
            TokenConfig({asset: asset, symbol: symbol, priceFeed: priceFeed, decimals: decimals});

        uint256 index = tokens.length;
        tokens.push(config);
        tokenIndex[asset] = index;
        tokenConfigs[asset] = config;
    }

    /// @notice Get all token configurations
    /// @return Array of TokenConfig structs
    function getAllTokens() external view returns (TokenConfig[] memory) {
        return tokens;
    }

    /// @notice Get number of configured tokens
    /// @return Number of tokens
    function getTokenCount() external view returns (uint256) {
        return tokens.length;
    }

    /// @notice Get token configuration by index
    /// @param index Token index
    /// @return TokenConfig struct
    function getTokenByIndex(uint256 index) external view returns (TokenConfig memory) {
        require(index < tokens.length, "Index out of bounds");
        return tokens[index];
    }

    /// @notice Get token configuration by asset address
    /// @param asset Token contract address
    /// @return TokenConfig struct
    function getTokenByAsset(address asset) external view returns (TokenConfig memory) {
        require(tokenConfigs[asset].asset != address(0), "Token not found");
        return tokenConfigs[asset];
    }
}

