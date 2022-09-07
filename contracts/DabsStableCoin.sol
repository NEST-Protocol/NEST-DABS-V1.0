// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "./libs/TransferHelper.sol";

import "./interfaces/IDabsStableCoin.sol";

import "./SimpleERC20.sol";

/// @dev This contract implemented the mining logic of nest
contract DabsStableCoin is SimpleERC20, IDabsStableCoin {

    /// @dev Index of project
    uint immutable PROJECT_ID;

    /// @dev Address of DabsPlatform
    address immutable DABS_PLATFORM;

    /// @dev Name of the token
    string _name;

    /// @dev Symbol of the token
    string _symbol;

    modifier onlyPlatform() {
        require(msg.sender == DABS_PLATFORM, "DabsStableCoin:not platform");
        _;
    }

    /// @dev Constructor
    /// @param name_ Name of the token
    /// @param symbol_ Symbol of the token
    /// @param projectId Index of project
    constructor(
        string memory name_,
        string memory symbol_,
        uint projectId
    ) {
        _name = name_;
        _symbol = symbol_;

        PROJECT_ID = projectId;
        DABS_PLATFORM = msg.sender;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @dev Mint 
    /// @param to Address to receive mined token
    /// @param amount Amount to mint
    function mint(address to, uint amount) external override onlyPlatform {
        _mint(to, amount);
    }

    /// @dev Mint ex
    /// @param account1 Address to receive mined token
    /// @param amount1 Amount to mint
    /// @param account2 Address to receive mined token
    /// @param amount2 Amount to mint
    function mintEx(address account1, uint256 amount1, address account2, uint amount2) external override onlyPlatform {
        _totalSupply += amount1 + amount2;
        _balances[account1] += amount1;
        _balances[account2] += amount2;
        emit Transfer(address(0), account1, amount1);
        emit Transfer(address(0), account2, amount2);
    }

    /// @dev Burn
    /// @param from Address to burn token
    /// @param amount Amount to burn
    function burn(address from, uint amount) external override onlyPlatform {
        _burn(from, amount);
    }

    /// @dev Pay
    /// @param target Address of target token
    /// @param to Address to receive token
    /// @param value Pay value
    function pay(address target, address to, uint value) external override onlyPlatform {
        if (target == address(0)) {
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(target, to, value);
        }
    }

    receive() external payable {
    }
}