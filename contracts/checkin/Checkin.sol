// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CheckInContract is Ownable {
  mapping(address => uint256) public lastCheckInTimestamp;
  mapping(address => uint256) public totalCheckInDays;
  // 为每次签到存储额外的元数据（如积分等信息）
  mapping(address => mapping(uint256 => bytes)) public checkInMetadata;

  // 声明一个可信的 Relayer 地址
  address public relayerAddress;

  event CheckedIn(
    address indexed user,
    uint256 timestamp,
    uint256 totalDays,
    bytes metadata // 添加 metadata 到事件中
  );

  constructor() Ownable(msg.sender) {}

  /**
   * @dev 由 Relayer 调用的核心签到函数
   * @param user 要为其签到的用户地址。
   * @param metadata 额外的元数据，例如积分信息（可选）。
   */
  function checkInFor(address user, bytes calldata metadata) public {
    // 只有被授权的 Relayer 才能调用此函数
    require(
      msg.sender == relayerAddress,
      "Caller is not the authorized relayer"
    );

    uint256 lastDay = lastCheckInTimestamp[user] / 1 days;
    uint256 today = block.timestamp / 1 days;
    require(lastDay < today, "CheckIn: Already checked in today");

    lastCheckInTimestamp[user] = block.timestamp;
    totalCheckInDays[user]++;

    // 存储元数据（如果有）
    if (metadata.length > 0) {
      checkInMetadata[user][today] = metadata;
    }

    emit CheckedIn(user, block.timestamp, totalCheckInDays[user], metadata);
  }

  /**
   * @dev 设置 Relayer 地址的函数，只有合约所有者可以调用。
   * @param _relayer 新的 Relayer 地址。
   */
  function setRelayer(address _relayer) public onlyOwner {
    relayerAddress = _relayer;
  }

  /**
   * @dev 获取指定用户某天的签到元数据
   * @param user 用户地址
   * @param day 日期（天数，与 block.timestamp / 1 days 相同格式）
   */
  function getCheckInMetadata(
    address user,
    uint256 day
  ) public view returns (bytes memory) {
    return checkInMetadata[user][day];
  }
}
