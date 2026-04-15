// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";
import {ITokensRegistry} from "./interface/ITokensRegistry.sol";

/// @title TokensRegistry
/// @notice Admin-managed token list seeded with Monad mainnet reserves.
contract TokensRegistry is ITokensRegistry {
    /// @notice Caller is not `admin`.
    error Unauthorized();
    /// @notice `initialAdmin` or `newAdmin` was zero.
    error InvalidAdmin();
    /// @notice Token insert used zero `asset`.
    error ZeroAsset();
    /// @notice Token insert used zero `priceFeed`.
    error ZeroPriceFeed();
    /// @notice `addToken` attempted to list an asset twice.
    error AssetAlreadyListed();
    /// @notice Mutation targeted an asset that is not listed.
    error AssetNotListed();
    /// @notice `removeTokenByIndex` used an out-of-range index.
    error InvalidTokenIndex();

    /// @notice Emitted when `admin` is rotated.
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    /// @notice Emitted when a token row is appended.
    event TokenAdded(address indexed asset, string symbol);
    /// @notice Emitted when a token row is removed.
    event TokenRemoved(address indexed asset);
    /// @notice Emitted when a token row is replaced in-place.
    event TokenUpdated(address indexed asset, string symbol);

    /// @notice Governance key allowed to mutate listings.
    address public admin;
    TokensConfig.Token[] private tokens;

    /// @notice Restricts mutating calls to `admin`.
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    /// @notice Initializes `admin` and seeds the Monad mainnet listing.
    /// @param initialAdmin Non-zero admin address.
    constructor(address initialAdmin) {
        if (initialAdmin == address(0)) revert InvalidAdmin();
        admin = initialAdmin;
        _seedMonadMainnet();
    }

    /// @notice Transfers admin rights to `newAdmin`.
    /// @param newAdmin Next admin address.
    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert InvalidAdmin();
        address previousAdmin = admin;
        admin = newAdmin;
        emit AdminUpdated(previousAdmin, newAdmin);
    }

    /// @inheritdoc ITokensRegistry
    function getTokens() external view override returns (TokensConfig.Token[] memory out) {
        uint256 n = tokens.length;
        out = new TokensConfig.Token[](n);
        for (uint256 i = 0; i < n; i++) {
            out[i] = tokens[i];
        }
    }

    /// @inheritdoc ITokensRegistry
    function tokenCount() external view override returns (uint256) {
        return tokens.length;
    }

    /// @notice Appends `token` to the listing.
    /// @param token Full metadata row for the reserve.
    function addToken(TokensConfig.Token calldata token) external onlyAdmin {
        if (token.asset == address(0)) revert ZeroAsset();
        if (token.priceFeed == address(0)) revert ZeroPriceFeed();
        if (_findAssetIndex(token.asset) != type(uint256).max) revert AssetAlreadyListed();
        tokens.push(token);
        emit TokenAdded(token.asset, token.symbol);
    }

    /// @notice Removes the row whose `asset` matches using swap-and-pop.
    /// @param asset Underlying asset address to remove.
    function removeTokenByAsset(address asset) external onlyAdmin {
        if (asset == address(0)) revert ZeroAsset();
        uint256 idx = _findAssetIndex(asset);
        if (idx == type(uint256).max) revert AssetNotListed();
        tokens[idx] = tokens[tokens.length - 1];
        tokens.pop();
        emit TokenRemoved(asset);
    }

    /// @notice Removes the row at `index` using swap-and-pop.
    /// @param index Zero-based position in the storage array.
    function removeTokenByIndex(uint256 index) external onlyAdmin {
        if (index >= tokens.length) revert InvalidTokenIndex();
        address asset = tokens[index].asset;
        tokens[index] = tokens[tokens.length - 1];
        tokens.pop();
        emit TokenRemoved(asset);
    }

    /// @notice Replaces the listing for `asset` with `token`.
    /// @param asset Existing underlying address to match.
    /// @param token Replacement metadata row (typically same `asset`).
    function updateToken(address asset, TokensConfig.Token calldata token) external onlyAdmin {
        if (token.asset == address(0)) revert ZeroAsset();
        if (token.priceFeed == address(0)) revert ZeroPriceFeed();
        uint256 idx = _findAssetIndex(asset);
        if (idx == type(uint256).max) revert AssetNotListed();
        tokens[idx] = token;
        emit TokenUpdated(token.asset, token.symbol);
    }

    /// @notice Linear scan for `asset`.
    /// @param asset Underlying address to locate.
    /// @return index Position in storage or `type(uint256).max` when missing.
    function _findAssetIndex(address asset) private view returns (uint256 index) {
        uint256 n = tokens.length;
        for (uint256 i = 0; i < n; i++) {
            if (tokens[i].asset == asset) return i;
        }
        return type(uint256).max;
    }

    /// @notice Seeds canonical Monad mainnet production assets.
    function _seedMonadMainnet() private {
        tokens.push(
            TokensConfig.Token({
                asset: 0x754704Bc059F8C67012fEd69BC8A327a5aafb603,
                priceFeed: 0xf5F15f188AbCB0d165D1Edb7f37F7d6fA2fCebec,
                decimals: 6,
                symbol: "USDC"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a,
                priceFeed: 0xE20751C7B5867bCBef815ffc1b284c3f412a9e13,
                decimals: 18,
                symbol: "AUSD"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417,
                priceFeed: 0xe6cd21b31948503dB54A07875999979722504B9A,
                decimals: 18,
                symbol: "wstETH"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242,
                priceFeed: 0x1B1414782B859871781bA3E4B0979b9ca57A0A04,
                decimals: 18,
                symbol: "WETH"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0xe7cd86e13AC4309349F30B3435a9d337750fC82D,
                priceFeed: 0x1a1Be4c184923a6BFF8c27cfDf6ac8bDE4DE00FC,
                decimals: 6,
                symbol: "USDT0"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0x4809010926aec940b550D34a46A52739f996D75D,
                priceFeed: 0x99bb13E956ba6e25624cAe95A41ED705AeA2557d,
                decimals: 18,
                symbol: "WSRUSD"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c,
                priceFeed: 0x2D1Df1bD061AAc38C22407AD69d69bCC3C62edBD,
                decimals: 8,
                symbol: "WBTC"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A,
                priceFeed: 0xBcD78f76005B7515837af6b50c7C52BCf73822fb,
                decimals: 18,
                symbol: "WMON"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c,
                priceFeed: 0x4f9ba5CaE0e3F651821283EC4e303fE8D1dA542a,
                decimals: 18,
                symbol: "SHMON"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0xA3227C5969757783154C60bF0bC1944180ed81B9,
                priceFeed: 0x80Efb6394E142F778cdD7F59b6Ee484B5a6299EB,
                decimals: 18,
                symbol: "SMON"
            })
        );
        tokens.push(
            TokensConfig.Token({
                asset: 0x8498312A6B3CbD158bf0c93AbdCF29E6e4F55081,
                priceFeed: 0xE53969561603a9052E3F579b2992C12F3C783496,
                decimals: 18,
                symbol: "GMON"
            })
        );
    }
}
