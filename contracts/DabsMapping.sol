// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./DabsBase.sol";

/// @dev The contract is for dabs builtin contract address mapping
abstract contract DabsMapping is DabsBase, IDabsMapping {

    /// @dev Address of DabsPlatform
    address _dabsPlatform;

    /// @dev address of DabsLedger
    address _dabsLedger;

    /// @dev Address of CofixRouter
    address _cofixRouter;

    /// @dev Address of NestOpenPlatform
    address _nestOpenPlatform;

    /// @dev Address of usdt
    address _usdtToken;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

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
    ) external override onlyGovernance {
        
        if (dabsPlatform != address(0)) {
            _dabsPlatform = dabsPlatform;
        }
        if (dabsLedger != address(0)) {
            _dabsLedger = dabsLedger;
        }
        if (cofixRouter != address(0)) {
            _cofixRouter = cofixRouter;
        }
        if (nestOpenPlatform != address(0)) {
            _nestOpenPlatform = nestOpenPlatform;
        }
        if (usdtToken != address(0)) {
            _usdtToken = usdtToken;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return dabsPlatform Address of DabsPlatform
    /// @return dabsLedger Address of DabsLedger
    /// @return cofixRouter Address of CoFiXRouter
    /// @return nestOpenPlatform Address of NestOpenPlatform
    /// @return usdtToken Address of usdt
    function getBuiltinAddress() external view override returns (
        address dabsPlatform,
        address dabsLedger,
        address cofixRouter,
        address nestOpenPlatform,
        address usdtToken
    ) {
        return (
            _dabsPlatform,
            _dabsLedger,
            _cofixRouter,
            _nestOpenPlatform,
            _usdtToken
        );
    }

    /// @dev Registered address. The address registered here is the address accepted by dabs system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external override onlyGovernance {
        _registeredAddress[key] = addr;
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view override returns (address) {
        return _registeredAddress[key];
    }
}