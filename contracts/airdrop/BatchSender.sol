// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BatchSender
 * @dev This contract allows a robot to send ERC20 tokens to multiple addresses in a single transaction.
 * Only admin can withdraw tokens and gas.
 */
contract BatchSender is Ownable {
  address public admin;

  event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
  event BatchSent(
    IERC20 indexed token,
    address[] recipients,
    uint256[] amounts
  );

  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  modifier onlyRobot() {
    _onlyRobot();
    _;
  }

  function _onlyAdmin() internal view {
    require(
      msg.sender == admin,
      "BatchSender: Only admin can call this function"
    );
  }

  function _onlyRobot() internal view {
    require(
      msg.sender == owner(),
      "BatchSender: Only robot can call this function"
    );
  }

  constructor(address _admin) Ownable(msg.sender) {
    require(_admin != address(0), "BatchSender: Invalid admin address");
    admin = _admin;
  }

  /**
   * @dev Sets a new admin address.
   * @param _newAdmin The new admin address.
   */
  function setAdmin(address _newAdmin) external onlyOwner {
    require(_newAdmin != address(0), "BatchSender: Invalid admin address");
    address oldAdmin = admin;
    admin = _newAdmin;
    emit AdminChanged(oldAdmin, _newAdmin);
  }

  /**
   * @dev Sends tokens to multiple recipients. Only robot can call this.
   * @notice The contract must be pre-funded with enough tokens.
   * @param _token The address of the ERC20 token to send.
   * @param _recipients An array of addresses to send tokens to.
   * @param _amounts An array of token amounts to send. Must have the same length as _recipients.
   */
  function batchSend(
    IERC20 _token,
    address[] calldata _recipients,
    uint256[] calldata _amounts
  ) external onlyRobot {
    require(
      _recipients.length == _amounts.length,
      "BatchSender: Mismatched array lengths"
    );

    for (uint256 i = 0; i < _recipients.length; i++) {
      require(
        _recipients[i] != address(0),
        "BatchSender: Invalid recipient address"
      );
      // The actual transfer happens here
      _token.transfer(_recipients[i], _amounts[i]);
    }

    emit BatchSent(_token, _recipients, _amounts);
  }

  /**
   * @dev Allows the admin to withdraw any accidentally sent ETH from the contract.
   */
  function withdrawEther() external onlyAdmin {
    payable(admin).transfer(address(this).balance);
  }

  /**
   * @dev Allows the admin to withdraw any accidentally sent ERC20 tokens.
   * @param _token The address of the ERC20 token to withdraw.
   */
  function withdrawTokens(IERC20 _token) external onlyAdmin {
    _token.transfer(admin, _token.balanceOf(address(this)));
  }

  /**
   * @dev Allows the admin to withdraw specific amount of ERC20 tokens.
   * @param _token The address of the ERC20 token to withdraw.
   * @param _amount The amount of tokens to withdraw.
   */
  function withdrawTokensAmount(
    IERC20 _token,
    uint256 _amount
  ) external onlyAdmin {
    require(_amount > 0, "BatchSender: Amount must be greater than 0");
    require(
      _amount <= _token.balanceOf(address(this)),
      "BatchSender: Insufficient balance"
    );
    _token.transfer(admin, _amount);
  }
}
