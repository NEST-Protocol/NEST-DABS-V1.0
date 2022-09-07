// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @dev This contract implemented the mining logic of nest dabs
interface IDabsVaultForStaking {

    /// @dev Get staked amount of target address
    /// @param projectId project Index
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(uint projectId, address addr) external view returns (uint);

    /// @dev Get the amount of reward
    /// @param projectId project Index
    /// @param addr Target address
    /// @return The amount of reward
    function earned(uint projectId, address addr) external view returns (uint);

    /// @dev Stake stablecoin and to earn reward
    /// @param projectId project Index
    /// @param amount Stake amount
    function stake(uint projectId, uint amount) external;

    /// @dev Withdraw stablecoin and claim reward
    /// @param projectId project Index
    function withdraw(uint projectId) external;

    /// @dev Claim reward
    /// @param projectId project Index
    function getReward(uint projectId) external;
}