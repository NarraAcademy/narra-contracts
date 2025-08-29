// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PointsContract
 * @dev 这个合约使用 Merkle Tree 来验证用户在链下的积分，以便在链上兑换奖励。
 * - 后端服务负责生成 Merkle Tree 并更新 root。
 * - 用户提交自己的积分和 proof 来证明其有效性。
 */
contract PointsContract is Ownable {
  // 存储由后端服务更新的 Merkle Root
  bytes32 public merkleRoot;

  // 记录每个用户已经消耗（领取）过的奖励，防止重放攻击
  // mapping(用户地址 => 已领取的奖励类型 => 是否已领取)
  // 例如: mapping(0x123... => keccak256("NFT_SKIN_1") => true)
  mapping(address => mapping(bytes32 => bool)) public claimed;

  event StateRootUpdated(bytes32 indexed newRoot, uint256 timestamp);
  event PointsClaimed(
    address indexed user,
    bytes32 indexed claimType,
    uint256 points
  );

  constructor() Ownable(msg.sender) {}

  /**
   * @dev 更新 Merkle Root，只有合约所有者（即你的后端 Relayer）可以调用。
   * @param _newRoot 新的 Merkle Root。
   */
  function updateStateRoot(bytes32 _newRoot) public onlyOwner {
    merkleRoot = _newRoot;
    emit StateRootUpdated(_newRoot, block.timestamp);
  }

  /**
   * @dev 用户使用积分来兑换奖励。
   * @param user 用户的地址。
   * @param points 用户拥有的积分数量（必须与后端生成 Merkle Tree 时的数据一致）。
   * @param claimType 一个唯一的标识符，代表本次领取的奖励类型，防止重放。
   * @param merkleProof 由后端为用户生成的 Merkle 树证明。
   */
  function claimReward(
    address user,
    uint256 points,
    bytes32 claimType,
    bytes32[] calldata merkleProof
  ) public {
    // 1. 安全检查：确保调用者就是凭证对应的用户，防止代领
    require(msg.sender == user, "Caller is not the user");

    // 2. 检查该奖励是否已经被领取过
    require(!claimed[user][claimType], "Reward already claimed");

    // 3. 构建叶子节点 (必须与后端生成叶子的方式完全一致)
    bytes32 leaf = keccak256(abi.encodePacked(user, points));

    // 4. 验证 Merkle Proof
    // MerkleProof.verify 会用 leaf 和 proof 计算出一个 root，
    // 然后与合约中存储的 merkleRoot 进行比对。
    require(
      MerkleProof.verify(merkleProof, merkleRoot, leaf),
      "Invalid Merkle proof"
    );

    // --- 验证成功后的业务逻辑 ---
    // 例如，你可以检查积分是否满足某个门槛
    // require(points >= 1000, "Not enough points for this reward");
    // 然后在这里铸造一个 NFT 给用户，或者调用另一个合约等。

    // 5. 将本次领取标记为已完成
    claimed[user][claimType] = true;

    emit PointsClaimed(user, claimType, points);
  }
}
