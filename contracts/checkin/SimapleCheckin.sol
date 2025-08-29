// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title SimplifiedCheckIn Contract with EIP-712
 * @dev This contract allows users to check in by providing a signature.
 * WARNING: This simplified version is vulnerable to replay attacks by design.
 * A signature can be captured and reused on any future day.
 * The contract only prevents more than one check-in per day on-chain.
 */
contract SimplifiedCheckIn is EIP712 {
  using ECDSA for bytes32;

  // --- Structs ---
  struct UserInfo {
    uint256 lastCheckInTime;
    uint256 totalCheckIns;
  }

  // --- State Variables ---
  mapping(address => UserInfo) public userInfo;

  // --- EIP-712 Type Hashes ---
  bytes32 private constant CHECKIN_TYPEHASH =
    keccak256("CheckIn(address user)");

  // --- Events ---
  event UserCheckedIn(
    address indexed user,
    uint256 checkInTime,
    uint256 totalCheckIns
  );

  /**
   * @dev Sets up the EIP-712 domain separator.
   */
  constructor() EIP712("Welcome to Narra Arena", "1") {}

  /**
   * @dev The main function for a user to perform their daily check-in via signature.
   * @param user The address of the user who is checking in.
   * @param signature The EIP-712 signature from the user (only signs their address).
   */
  function checkInWithSignature(address user, bytes calldata signature) public {
    UserInfo storage currentUser = userInfo[user];

    uint256 currentDay = block.timestamp / 1 days;
    uint256 lastCheckInDay = currentUser.lastCheckInTime / 1 days;
    require(
      currentDay > lastCheckInDay,
      "CheckIn: You can only check in once per 24 hours."
    );

    bytes32 digest = _hashTypedDataV4(
      keccak256(abi.encode(CHECKIN_TYPEHASH, user))
    );

    address signer = digest.recover(signature);
    require(signer != address(0), "ECDSA: invalid signature");
    require(signer == user, "CheckIn: Invalid signature");

    currentUser.lastCheckInTime = block.timestamp;
    currentUser.totalCheckIns++;

    emit UserCheckedIn(
      user,
      currentUser.lastCheckInTime,
      currentUser.totalCheckIns
    );
  }

  /**
   * @dev A view function to retrieve the check-in information for a specific user.
   * @param _user The address of the user to query.
   * @return lastCheckInTime The timestamp of the last check-in.
   * @return totalCheckIns The total number of check-ins.
   */
  function getUserInfo(address _user) public view returns (uint256, uint256) {
    UserInfo storage user = userInfo[_user];
    return (user.lastCheckInTime, user.totalCheckIns);
  }

  /**
   * @dev Check if a user can check in now.
   * @param _user The address of the user to check.
   * @return True if user can check in, false otherwise.
   */
  function canCheckIn(address _user) public view returns (bool) {
    UserInfo storage user = userInfo[_user];
    uint256 currentDay = block.timestamp / 1 days;
    uint256 lastCheckInDay = user.lastCheckInTime / 1 days;
    return currentDay > lastCheckInDay;
  }

  /**
   * @dev Get the next check-in time for a user.
   * @param _user The address of the user.
   * @return The timestamp when the user can check in next.
   */
  function getNextCheckInTime(address _user) public view returns (uint256) {
    UserInfo storage user = userInfo[_user];
    if (user.lastCheckInTime == 0) {
      return 0; // Can check in immediately
    }
    uint256 lastCheckInDay = user.lastCheckInTime / 1 days;
    return (lastCheckInDay + 1) * 1 days;
  }

  /**
   * @dev A view function to retrieve the domain separator.
   * @return The domain separator.
   */
  function getDomainSeparator() public view returns (bytes32) {
    return _domainSeparatorV4();
  }
}
