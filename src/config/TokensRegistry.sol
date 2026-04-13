// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {TokensConfig} from "./TokensConfig.sol";
import {ITokensRegistry} from "./interface/ITokensRegistry.sol";

/// @title TokensRegistry
/// @notice Admin-managed per-network token lists seeded for Arbitrum Sepolia and Monad mainnet.
/// @dev Network keys are internal `uint8` values derived from `TokensConfig.Network`.
contract TokensRegistry is ITokensRegistry {
    /// @notice Caller is not `admin`.
    error Unauthorized();
    /// @notice `initialAdmin` or `newAdmin` was zero.
    error InvalidAdmin();
    /// @notice Token insert used zero `asset`.
    error ZeroAsset();
    /// @notice Token insert used zero `priceFeed`.
    error ZeroPriceFeed();
    /// @notice `addToken` attempted to list an asset twice on the same network.
    error AssetAlreadyListed();
    /// @notice Mutation targeted an asset that is not listed.
    error AssetNotListed();
    /// @notice `removeTokenByIndex` used an out-of-range index.
    error InvalidTokenIndex();
    /// @notice `_networkKey` received an enum value without a storage bucket.
    error UnsupportedNetwork();

    /// @notice Emitted when `admin` is rotated.
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);
    /// @notice Emitted when a token row is appended for `networkKey`.
    event TokenAdded(uint8 indexed networkKey, address indexed asset, string symbol);
    /// @notice Emitted when a token row is removed for `networkKey`.
    event TokenRemoved(uint8 indexed networkKey, address indexed asset);
    /// @notice Emitted when a token row is replaced in-place for `networkKey`.
    event TokenUpdated(uint8 indexed networkKey, address indexed asset, string symbol);

    /// @notice Governance key allowed to mutate listings.
    address public admin;
    mapping(uint8 => TokensConfig.Token[]) private tokensByNetwork;

    /// @notice Restricts mutating calls to `admin`.
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    /// @notice Initializes `admin` and seeds default listings for both networks.
    /// @param initialAdmin Non-zero admin address.
    constructor(address initialAdmin) {
        if (initialAdmin == address(0)) revert InvalidAdmin();
        admin = initialAdmin;
        _seedArbitrumSepolia();
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
    function getTokens(TokensConfig.Network network) external view override returns (TokensConfig.Token[] memory out) {
        TokensConfig.Token[] storage t = tokensByNetwork[_networkKey(network)];
        out = new TokensConfig.Token[](t.length);
        for (uint256 i = 0; i < t.length; i++) {
            out[i] = t[i];
        }
    }

    /// @inheritdoc ITokensRegistry
    function tokenCount(TokensConfig.Network network) external view override returns (uint256) {
        return tokensByNetwork[_networkKey(network)].length;
    }

    /// @notice Appends `token` to the listing for `network`.
    /// @param network Target chain deployment.
    /// @param token Full metadata row for the reserve.
    function addToken(TokensConfig.Network network, TokensConfig.Token calldata token) external onlyAdmin {
        if (token.asset == address(0)) revert ZeroAsset();
        if (token.priceFeed == address(0)) revert ZeroPriceFeed();
        uint8 k = _networkKey(network);
        if (_findAssetIndex(k, token.asset) != type(uint256).max) revert AssetAlreadyListed();
        tokensByNetwork[k].push(token);
        emit TokenAdded(k, token.asset, token.symbol);
    }

    /// @notice Removes the row whose `asset` matches on `network` using swap-and-pop.
    /// @param network Target chain deployment.
    /// @param asset Underlying asset address to remove.
    function removeTokenByAsset(TokensConfig.Network network, address asset) external onlyAdmin {
        if (asset == address(0)) revert ZeroAsset();
        uint8 k = _networkKey(network);
        TokensConfig.Token[] storage arr = tokensByNetwork[k];
        uint256 idx = _findAssetIndex(k, asset);
        if (idx == type(uint256).max) revert AssetNotListed();
        arr[idx] = arr[arr.length - 1];
        arr.pop();
        emit TokenRemoved(k, asset);
    }

    /// @notice Removes the row at `index` on `network` using swap-and-pop.
    /// @param network Target chain deployment.
    /// @param index Zero-based position in the storage array.
    function removeTokenByIndex(TokensConfig.Network network, uint256 index) external onlyAdmin {
        uint8 k = _networkKey(network);
        TokensConfig.Token[] storage arr = tokensByNetwork[k];
        if (index >= arr.length) revert InvalidTokenIndex();
        address asset = arr[index].asset;
        arr[index] = arr[arr.length - 1];
        arr.pop();
        emit TokenRemoved(k, asset);
    }

    /// @notice Replaces the listing for `asset` with `token` on `network`.
    /// @param network Target chain deployment.
    /// @param asset Existing underlying address to match.
    /// @param token Replacement metadata row (typically same `asset`).
    function updateToken(TokensConfig.Network network, address asset, TokensConfig.Token calldata token)
        external
        onlyAdmin
    {
        if (token.asset == address(0)) revert ZeroAsset();
        if (token.priceFeed == address(0)) revert ZeroPriceFeed();
        uint8 k = _networkKey(network);
        uint256 idx = _findAssetIndex(k, asset);
        if (idx == type(uint256).max) revert AssetNotListed();
        tokensByNetwork[k][idx] = token;
        emit TokenUpdated(k, token.asset, token.symbol);
    }

    /// @notice Maps enum to compact uint8 storage key.
    /// @param network Supported network enumerator.
    /// @return k Internal bucket id.
    function _networkKey(TokensConfig.Network network) private pure returns (uint8 k) {
        if (network == TokensConfig.Network.ArbitrumSepolia) return 0;
        if (network == TokensConfig.Network.MonadMainnet) return 1;
        revert UnsupportedNetwork();
    }

    /// @notice Linear scan for `asset` within `k`.
    /// @param k Internal bucket id.
    /// @param asset Underlying address to locate.
    /// @return index Position in storage or `type(uint256).max` when missing.
    function _findAssetIndex(uint8 k, address asset) private view returns (uint256 index) {
        TokensConfig.Token[] storage arr = tokensByNetwork[k];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].asset == asset) return i;
        }
        return type(uint256).max;
    }

    /// @notice Seeds canonical Arbitrum Sepolia test assets.
    function _seedArbitrumSepolia() private {
        uint8 k = 0;
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73,
                priceFeed: 0x2d3bBa5e0A9Fd8EAa45Dcf71A2389b7C12005b1f,
                decimals: 18,
                symbol: "WETH"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d,
                priceFeed: 0x0153002d20B96532C639313c2d54c3dA09109309,
                decimals: 6,
                symbol: "USDC"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x30fA2FbE15c1EaDfbEF28C188b7B8dbd3c1Ff2eB,
                priceFeed: 0x80EDee6f667eCc9f63a0a6f55578F870651f06A4,
                decimals: 6,
                symbol: "USDT"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0xbC47901f4d2C5fc871ae0037Ea05c3F614690781,
                priceFeed: 0xb113F5A928BCfF189C998ab20d753a47F9dE5A61,
                decimals: 18,
                symbol: "DAI"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x152B0DF80135c63B4Cb1FBE00DDCE7E9a8FFCb04,
                priceFeed: 0x56a43EB56Da12C0dc1D972ACb089c06a5dEF8e69,
                decimals: 8,
                symbol: "BTC"
            })
        );
    }

    /// @notice Seeds canonical Monad mainnet production assets.
    function _seedMonadMainnet() private {
        uint8 k = 1;
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x754704Bc059F8C67012fEd69BC8A327a5aafb603,
                priceFeed: 0xf5F15f188AbCB0d165D1Edb7f37F7d6fA2fCebec,
                decimals: 6,
                symbol: "USDC"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a,
                priceFeed: 0xE20751C7B5867bCBef815ffc1b284c3f412a9e13,
                decimals: 18,
                symbol: "AUSD"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x10Aeaf63194db8d453d4D85a06E5eFE1dd0b5417,
                priceFeed: 0xe6cd21b31948503dB54A07875999979722504B9A,
                decimals: 18,
                symbol: "wstETH"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0xEE8c0E9f1BFFb4Eb878d8f15f368A02a35481242,
                priceFeed: 0x1B1414782B859871781bA3E4B0979b9ca57A0A04,
                decimals: 18,
                symbol: "WETH"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0xe7cd86e13AC4309349F30B3435a9d337750fC82D,
                priceFeed: 0x1a1Be4c184923a6BFF8c27cfDf6ac8bDE4DE00FC,
                decimals: 6,
                symbol: "USDT0"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x4809010926aec940b550D34a46A52739f996D75D,
                priceFeed: 0x99bb13E956ba6e25624cAe95A41ED705AeA2557d,
                decimals: 18,
                symbol: "WSRUSD"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c,
                priceFeed: 0x2D1Df1bD061AAc38C22407AD69d69bCC3C62edBD,
                decimals: 8,
                symbol: "WBTC"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A,
                priceFeed: 0xBcD78f76005B7515837af6b50c7C52BCf73822fb,
                decimals: 18,
                symbol: "WMON"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x1B68626dCa36c7fE922fD2d55E4f631d962dE19c,
                priceFeed: 0x4f9ba5CaE0e3F651821283EC4e303fE8D1dA542a,
                decimals: 18,
                symbol: "SHMON"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0xA3227C5969757783154C60bF0bC1944180ed81B9,
                priceFeed: 0x80Efb6394E142F778cdD7F59b6Ee484B5a6299EB,
                decimals: 18,
                symbol: "SMON"
            })
        );
        tokensByNetwork[k].push(
            TokensConfig.Token({
                asset: 0x8498312A6B3CbD158bf0c93AbdCF29E6e4F55081,
                priceFeed: 0xE53969561603a9052E3F579b2992C12F3C783496,
                decimals: 18,
                symbol: "GMON"
            })
        );
    }
}
