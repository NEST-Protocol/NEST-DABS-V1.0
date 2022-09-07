// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./interfaces/IDabsGovernance.sol";

/// @dev Base contract of nest
contract DabsBase {

    /// @dev IDabsGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IDabsGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "DABS:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IDabsGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IDabsGovernance(governance).checkGovernance(msg.sender, 0), "DABS:!gov");
        _governance = newGovernance;
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IDabsGovernance(_governance).checkGovernance(msg.sender, 0), "DABS:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "DABS:!contract");
        _;
    }
}