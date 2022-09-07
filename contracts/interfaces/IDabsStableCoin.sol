// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @dev This contract implemented the mining logic of nest
interface IDabsStableCoin {

    /// @dev Mint 
    /// @param to Address to receive mined token
    /// @param amount Amount to mint
    function mint(address to, uint amount) external;

    /// @dev Mint ex
    /// @param account1 Address to receive mined token
    /// @param amount1 Amount to mint
    /// @param account2 Address to receive mined token
    /// @param amount2 Amount to mint
    function mintEx(address account1, uint256 amount1, address account2, uint amount2) external;

    /// @dev Burn
    /// @param from Address to burn token
    /// @param amount Amount to burn
    function burn(address from, uint amount) external;

    /// @dev Pay
    /// @param target Address of target token
    /// @param to Address to receive token
    /// @param value Pay value
    function pay(address target, address to, uint value) external;
}