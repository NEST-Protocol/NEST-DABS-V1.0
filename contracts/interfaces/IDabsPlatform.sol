// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @dev This contract implemented the mining logic of nest dabs
interface IDabsPlatform {

    /// @dev New project event
    /// @param projectId Index of project
    /// @param target Reserve token address
    /// @param stablecoin Stablecoin address
    /// @param opener Opener of this project
    event NewProject(uint projectId, address target, address stablecoin, address opener);

    /// @dev Project information
    struct ProjectView {

        uint index;

        // The channelId for call nest price
        uint16 channelId;
        // The pairIndex for call nest price
        uint16 pairIndex;
        // Reward rate, 10000 points system, 2000 means 20%
        uint16 stakingRewardRate;
        uint48 sigmaSQ;// = 102739726027;
        // Reserve token address
        address target;

        // Post unit of target token in nest
        uint96 postUnit;
        // Stablecoin address
        address stablecoin;

        // Opener of this project
        address opener;
        uint32 openBlock;
    }
    
    /// @dev Find the projects of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param opener Target address
    /// @return projectArray Matched project array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address opener
    ) external view returns (ProjectView[] memory projectArray);

    /// @dev List projects
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return projectArray Matched project array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (ProjectView[] memory projectArray);

    /// @dev Obtain the number of projects that have been opened
    /// @return Number of projects opened
    function getProjectCount() external view returns (uint);

    /// @dev Open new project
    /// @param channelId The channelId for call nest price
    /// @param pairIndex The pairIndex for call nest price
    /// @param stakingRewardRate Reward rate
    function open(
        uint16 channelId,
        uint16 pairIndex,
        uint16 stakingRewardRate
    ) external;

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mint(uint projectId, uint amount) external payable;

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mintAndStake(uint projectId, uint amount) external payable;

    /// @dev Burn stablecoin and get target token
    /// @param projectId project Index
    /// @param amount Amount of stablecoin
    function burn(uint projectId, uint amount) external payable;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Calculate the impact cost
    /// @param vol Trade amount in dcu
    /// @return Impact cost
    function impactCost(uint vol) external pure returns (uint);

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ sigmaSQ for token
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) external view returns (uint k);
}