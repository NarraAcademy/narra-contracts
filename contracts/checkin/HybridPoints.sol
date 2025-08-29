// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title HybridPointsContract
 * @dev 结合了两种模式:
 * 1. 批量签到: 后端聚合用户的链下签名，一次性提交上链进行验证。
 * 2. Merkle 积分系统: 后端生成积分状态的 Merkle Root，用户提交 Proof 来兑换奖励。
 */
contract HybridPointsContract is Ownable, EIP712 {
  // --- Merkle 积分系统 ---
  bytes32 public merkleRoot;
  mapping(address => mapping(bytes32 => bool)) public claimed;

  // --- 批量签到系统 ---
  struct CheckInData {
    address user;
    uint256 dailyNonce; // 用于防止重放，通常是日期，例如 20240520
    bytes signature;
  }
  // 记录用户在哪一天已经签到
  mapping(address => mapping(uint256 => bool)) public hasCheckedIn;

  // --- 事件 ---
  event StateRootUpdated(bytes32 indexed newRoot);
  event PointsClaimed(
    address indexed user,
    bytes32 indexed claimType,
    uint256 points
  );
  event UserCheckedIn(address indexed user, uint256 indexed dailyNonce);

  // --- EIP712 ---
  // 定义了用户签名的结构体哈希，必须与前端/后端生成的一致
  bytes32 private constant CHECKIN_TYPEHASH =
    keccak256("CheckIn(address user,uint256 dailyNonce)");

  // EIP712 构造函数，设置域名和版本
  constructor() EIP712("HybridPointsContract", "1") Ownable(msg.sender) {}

  // 公共方法，用于测试和前端生成签名
  function getCheckInDigest(
    address user,
    uint256 dailyNonce
  ) public view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(CHECKIN_TYPEHASH, user, dailyNonce)
    );
    return _hashTypedDataV4(structHash);
  }

  // =================================================================
  // 积分系统函数
  // =================================================================

  function updateStateRoot(bytes32 _newRoot) public onlyOwner {
    merkleRoot = _newRoot;
    emit StateRootUpdated(_newRoot);
  }

  function claimReward(
    address user,
    uint256 points,
    bytes32 claimType,
    bytes32[] calldata merkleProof
  ) public {
    require(msg.sender == user, "Caller is not the user");
    require(!claimed[user][claimType], "Reward already claimed");
    bytes32 leaf = keccak256(abi.encodePacked(user, points));
    require(
      MerkleProof.verify(merkleProof, merkleRoot, leaf),
      "Invalid Merkle proof"
    );
    claimed[user][claimType] = true;
    emit PointsClaimed(user, claimType, points);
  }

  // =================================================================
  // 签到系统函数
  // =================================================================

  /**
   * @dev 批量处理签到数据，只能由后端 Relayer 调用。
   */
  function batchCheckIn(CheckInData[] calldata checkIns) public onlyOwner {
    for (uint256 i = 0; i < checkIns.length; i++) {
      address user = checkIns[i].user;
      uint256 nonce = checkIns[i].dailyNonce;

      // 1. 检查该用户当天是否已经签到
      if (!hasCheckedIn[user][nonce]) {
        // 2. 验证签名
        bytes32 structHash = keccak256(
          abi.encode(CHECKIN_TYPEHASH, user, nonce)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, checkIns[i].signature);

        // 3. 如果签名有效且来自该用户
        if (signer == user && signer != address(0)) {
          hasCheckedIn[user][nonce] = true;
          // 在这里，后端应该监听这个事件，并给用户的数据库积分 +10 (或其他数值)
          emit UserCheckedIn(user, nonce);
        }
      }
    }
  }
}
