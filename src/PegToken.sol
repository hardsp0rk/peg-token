// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract PegToken is ERC20PermitUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    function initialize(string memory _name, string memory _symbol) public initializer {
        __Context_init();
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Pausable_init();
    }

    /**
     * @dev See {IERC20-approve}.
     * @param spender Spender's address
     * @param amount Allowance amount
     * @return True if successful
     */
    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }

    /**
     * @dev See {IERC20-transfer}.
     * @param to Destination address
     * @param amount Transfer amount
     * @return True if successful
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     * @param from Owner's address
     * @param to Destination address
     * @param amount Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Triggers stopped state.
     * Can only be called by the current owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Can only be called by the current owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
