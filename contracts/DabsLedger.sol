// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./libs/TransferHelper.sol";
import "./DabsBase.sol";

/// @dev DABS ledger contract
contract DabsLedger is DabsBase {

    /// @dev Pay
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(address tokenAddress, address to, uint value) external onlyGovernance {

        // Pay eth from ledger
        if (tokenAddress == address(0)) {
            // pay
            payable(to).transfer(value);
        }
        // Pay token
        else {
            // pay
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    receive() external payable {
    }
}