// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @dev The interface defines methods for nest builtin contract address mapping
interface IDabsMapping {

    /// @dev Set the built-in contract address of the system
    /// @param dabsPlatform Address of DabsPlatform
    /// @param dabsLedger Address of DabsLedger
    /// @param cofixRouter Address of CoFiXRouter
    /// @param nestOpenPlatform Address of NestOpenPlatform
    /// @param usdtToken Address of usdt
    function setBuiltinAddress(
        address dabsPlatform,
        address dabsLedger,
        address cofixRouter,
        address nestOpenPlatform,
        address usdtToken
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return dabsPlatform Address of DabsPlatform
    /// @return dabsLedger Address of DabsLedger
    /// @return cofixRouter Address of CoFiXRouter
    /// @return nestOpenPlatform Address of NestOpenPlatform
    /// @return usdtToken Address of usdt
    function getBuiltinAddress() external view returns (
        address dabsPlatform,
        address dabsLedger,
        address cofixRouter,
        address nestOpenPlatform,
        address usdtToken
    );

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);
}