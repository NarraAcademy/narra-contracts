// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BurnToStake {
  // Dead address for burning tokens
  address public constant DEAD_ADDRESS =
    0x000000000000000000000000000000000000dEaD;

  // Event emitted when tokens are staked
  event Staked(address indexed account, uint256 amount);

  // Event emitted when tokens are delegated and staked
  event DelegateStaked(
    address indexed account,
    address indexed delegate,
    uint256 amount
  );

  /**
   * @dev Burn tokens by sending them to dead address (stake)
   * @param token The token contract address to burn
   * @param amount The amount of tokens to burn
   */
  function burnToStake(address token, uint256 amount) external {
    require(token != address(0), "Invalid token address");
    require(amount > 0, "Amount must be greater than 0");

    // Transfer tokens from user to dead address
    IERC20(token).transferFrom(msg.sender, DEAD_ADDRESS, amount);

    // Emit Staked event
    emit Staked(msg.sender, amount);
  }

  /**
   * @dev Burn tokens and delegate stake to another address
   * @param token The token contract address to burn
   * @param amount The amount of tokens to burn
   * @param delegate The address to delegate the stake to
   */
  function burnToStakeWithDelegate(
    address token,
    uint256 amount,
    address delegate
  ) external {
    require(token != address(0), "Invalid token address");
    require(amount > 0, "Amount must be greater than 0");
    require(delegate != address(0), "Invalid delegate address");

    // Transfer tokens from user to dead address
    IERC20(token).transferFrom(msg.sender, DEAD_ADDRESS, amount);

    // Emit DelegateStaked event
    emit DelegateStaked(msg.sender, delegate, amount);
  }
}
