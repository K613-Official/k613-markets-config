// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IACLManager
/// @notice Interface for Aave v3 ACLManager
interface IACLManager {
    /// @notice Adds an address as Asset Listing Admin
    /// @param admin The address to add as Asset Listing Admin
    function addAssetListingAdmin(address admin) external;

    /// @notice Removes an address from Asset Listing Admin role
    /// @param admin The address to remove from Asset Listing Admin role
    function removeAssetListingAdmin(address admin) external;

    /// @notice Returns true if the address is an Asset Listing Admin
    /// @param admin The address to check
    /// @return True if the address is an Asset Listing Admin
    function isAssetListingAdmin(address admin) external view returns (bool);

    /// @notice Adds an address as Pool Admin
    /// @param admin The address to add as Pool Admin
    function addPoolAdmin(address admin) external;

    /// @notice Removes an address from Pool Admin role
    /// @param admin The address to remove from Pool Admin role
    function removePoolAdmin(address admin) external;

    /// @notice Returns true if the address is a Pool Admin
    /// @param admin The address to check
    /// @return True if the address is a Pool Admin
    function isPoolAdmin(address admin) external view returns (bool);
}
