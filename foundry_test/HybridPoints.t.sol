// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from "../lib/forge-std/src/Test.sol";
import { HybridPointsContract } from "../contracts/checkin/HybridPoints.sol";

contract HybridPointsTest is Test {
  HybridPointsContract public hybridPoints;
  address public owner;
  address public user1;
  address public user2;

  // 测试用的 Merkle Tree 数据
  bytes32 public merkleRoot;
  bytes32[] public proof1;
  bytes32[] public proof2;

  function setUp() public {
    owner = makeAddr("owner");
    user1 = makeAddr("user1");
    user2 = makeAddr("user2");

    // 部署合约
    vm.startPrank(owner);
    hybridPoints = new HybridPointsContract();
    vm.stopPrank();

    // 设置 Merkle Tree
    setupMerkleTree();
  }

  // 模拟后端生成 Merkle Tree 的过程
  function setupMerkleTree() internal {
    // 构建叶子节点
    bytes32 leaf1 = keccak256(abi.encodePacked(user1, uint256(1000)));
    bytes32 leaf2 = keccak256(abi.encodePacked(user2, uint256(2000)));

    // 计算 root（简化版本）
    merkleRoot = keccak256(abi.encodePacked(leaf1, leaf2));

    // 生成 proof
    proof1 = new bytes32[](1);
    proof1[0] = leaf2;

    proof2 = new bytes32[](1);
    proof2[0] = leaf1;

    // 更新合约中的 merkle root
    vm.startPrank(owner);
    hybridPoints.updateStateRoot(merkleRoot);
    vm.stopPrank();
  }

  // =================================================================
  // Merkle 积分系统测试
  // =================================================================

  function test_Constructor() public view {
    assertEq(hybridPoints.owner(), owner);
    assertEq(hybridPoints.merkleRoot(), merkleRoot);
  }

  function test_UpdateStateRoot() public {
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));

    vm.startPrank(owner);
    hybridPoints.updateStateRoot(newRoot);
    vm.stopPrank();

    assertEq(hybridPoints.merkleRoot(), newRoot);
  }

  function test_UpdateStateRoot_Unauthorized() public {
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));

    vm.startPrank(user1);
    vm.expectRevert(); // Ownable: caller is not the owner
    hybridPoints.updateStateRoot(newRoot);
    vm.stopPrank();
  }

  function test_ClaimReward() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    vm.startPrank(user1);
    hybridPoints.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();

    assertTrue(hybridPoints.claimed(user1, claimType));
  }

  function test_ClaimReward_NotUser() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    vm.startPrank(user2);
    vm.expectRevert("Caller is not the user");
    hybridPoints.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }

  function test_ClaimReward_AlreadyClaimed() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    vm.startPrank(user1);
    hybridPoints.claimReward(user1, 1000, claimType, proof1);

    vm.expectRevert("Reward already claimed");
    hybridPoints.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }

  function test_ClaimReward_InvalidProof() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));
    bytes32[] memory invalidProof = new bytes32[](1);
    invalidProof[0] = keccak256(abi.encodePacked("invalid"));

    vm.startPrank(user1);
    vm.expectRevert("Invalid Merkle proof");
    hybridPoints.claimReward(user1, 1000, claimType, invalidProof);
    vm.stopPrank();
  }

  function test_ClaimReward_DifferentTypes() public {
    bytes32 claimType1 = keccak256(abi.encodePacked("NFT_SKIN_1"));
    bytes32 claimType2 = keccak256(abi.encodePacked("NFT_SKIN_2"));

    vm.startPrank(user1);
    hybridPoints.claimReward(user1, 1000, claimType1, proof1);
    hybridPoints.claimReward(user1, 1000, claimType2, proof1);
    vm.stopPrank();

    assertTrue(hybridPoints.claimed(user1, claimType1));
    assertTrue(hybridPoints.claimed(user1, claimType2));
  }

  // =================================================================
  // 事件测试
  // =================================================================

  function test_Events() public {
    // 测试 StateRootUpdated 事件
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));
    vm.startPrank(owner);
    vm.expectEmit(true, false, false, true);
    emit HybridPointsContract.StateRootUpdated(newRoot);
    hybridPoints.updateStateRoot(newRoot);
    vm.stopPrank();

    // 重新设置 merkle root 以便测试其他事件
    vm.startPrank(owner);
    hybridPoints.updateStateRoot(merkleRoot);
    vm.stopPrank();

    // 测试 PointsClaimed 事件
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));
    vm.startPrank(user1);
    vm.expectEmit(true, true, false, true);
    emit HybridPointsContract.PointsClaimed(user1, claimType, 1000);
    hybridPoints.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }

  // =================================================================
  // 签到系统基础测试
  // =================================================================

  function test_GetCheckInDigest() public view {
    uint256 dailyNonce = 20240520;
    bytes32 digest = hybridPoints.getCheckInDigest(user1, dailyNonce);

    // 验证 digest 不为零
    assertTrue(digest != bytes32(0));
  }

  function test_BatchCheckIn_Unauthorized() public {
    uint256 dailyNonce = 20240520;

    // 创建一个空的签到数据数组
    HybridPointsContract.CheckInData[]
      memory checkIns = new HybridPointsContract.CheckInData[](0);

    vm.startPrank(user1);
    vm.expectRevert(); // Ownable: caller is not the owner
    hybridPoints.batchCheckIn(checkIns);
    vm.stopPrank();
  }
}
