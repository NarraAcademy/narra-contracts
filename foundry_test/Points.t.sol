// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from "../lib/forge-std/src/Test.sol";
import { PointsContract } from "../contracts/Points.sol";

contract PointsTest is Test {
  PointsContract public points;
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
    points = new PointsContract();
    vm.stopPrank();

    // 模拟后端生成的 Merkle Tree
    // 假设有两个用户：user1(1000积分), user2(2000积分)
    setupMerkleTree();
  }

  // 模拟后端生成 Merkle Tree 的过程
  function setupMerkleTree() internal {
    // 构建叶子节点：keccak256(abi.encodePacked(user, points))
    bytes32 leaf1 = keccak256(abi.encodePacked(user1, uint256(1000)));
    bytes32 leaf2 = keccak256(abi.encodePacked(user2, uint256(2000)));

    // 模拟 Merkle Tree 构建过程
    // 这里简化处理，实际应该由后端生成
    bytes32[] memory leaves = new bytes32[](2);
    leaves[0] = leaf1;
    leaves[1] = leaf2;

    // 计算 root（简化版本）
    merkleRoot = keccak256(abi.encodePacked(leaf1, leaf2));

    // 为 user1 生成 proof（简化版本）
    proof1 = new bytes32[](1);
    proof1[0] = leaf2;

    // 为 user2 生成 proof（简化版本）
    proof2 = new bytes32[](1);
    proof2[0] = leaf1;

    // 更新合约中的 merkle root
    vm.startPrank(owner);
    points.updateStateRoot(merkleRoot);
    vm.stopPrank();
  }

  // 测试合约构造函数
  function test_Constructor() public view {
    assertEq(points.owner(), owner);
    assertEq(points.merkleRoot(), merkleRoot);
  }

  // 测试 owner 可以更新 Merkle Root
  function test_UpdateStateRoot() public {
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));

    vm.startPrank(owner);
    points.updateStateRoot(newRoot);
    vm.stopPrank();

    assertEq(points.merkleRoot(), newRoot);
  }

  // 测试非 owner 不能更新 Merkle Root
  function test_UpdateStateRoot_Unauthorized() public {
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));

    vm.startPrank(user1);
    vm.expectRevert(); // Ownable: caller is not the owner
    points.updateStateRoot(newRoot);
    vm.stopPrank();
  }

  // 测试用户正常领取奖励
  function test_ClaimReward() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    vm.startPrank(user1);
    points.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();

    // 检查是否标记为已领取
    assertTrue(points.claimed(user1, claimType));
  }

  // 测试用户不能代领其他用户的奖励
  function test_ClaimReward_NotUser() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    vm.startPrank(user2);
    vm.expectRevert("Caller is not the user");
    points.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }

  // 测试重复领取会失败
  function test_ClaimReward_AlreadyClaimed() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    vm.startPrank(user1);
    points.claimReward(user1, 1000, claimType, proof1);

    // 再次领取应失败
    vm.expectRevert("Reward already claimed");
    points.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }

  // 测试无效的 Merkle Proof 会失败
  function test_ClaimReward_InvalidProof() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));
    bytes32[] memory invalidProof = new bytes32[](1);
    invalidProof[0] = keccak256(abi.encodePacked("invalid"));

    vm.startPrank(user1);
    vm.expectRevert("Invalid Merkle proof");
    points.claimReward(user1, 1000, claimType, invalidProof);
    vm.stopPrank();
  }

  // 测试不同用户领取不同奖励类型
  function test_ClaimReward_DifferentTypes() public {
    bytes32 claimType1 = keccak256(abi.encodePacked("NFT_SKIN_1"));
    bytes32 claimType2 = keccak256(abi.encodePacked("NFT_SKIN_2"));

    // user1 领取第一种奖励
    vm.startPrank(user1);
    points.claimReward(user1, 1000, claimType1, proof1);
    vm.stopPrank();

    // user2 领取第二种奖励
    vm.startPrank(user2);
    points.claimReward(user2, 2000, claimType2, proof2);
    vm.stopPrank();

    // 检查两种奖励都被标记为已领取
    assertTrue(points.claimed(user1, claimType1));
    assertTrue(points.claimed(user2, claimType2));
  }

  // 测试同一用户可以领取不同类型的奖励
  function test_ClaimReward_SameUserDifferentTypes() public {
    bytes32 claimType1 = keccak256(abi.encodePacked("NFT_SKIN_1"));
    bytes32 claimType2 = keccak256(abi.encodePacked("NFT_SKIN_2"));

    vm.startPrank(user1);
    points.claimReward(user1, 1000, claimType1, proof1);
    points.claimReward(user1, 1000, claimType2, proof1);
    vm.stopPrank();

    // 检查两种奖励都被标记为已领取
    assertTrue(points.claimed(user1, claimType1));
    assertTrue(points.claimed(user1, claimType2));
  }

  // 测试更新 Merkle Root 后，旧的 proof 失效
  function test_ClaimReward_OldProofInvalidAfterRootUpdate() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    // 先更新 merkle root
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));
    vm.startPrank(owner);
    points.updateStateRoot(newRoot);
    vm.stopPrank();

    // 尝试用旧的 proof 领取奖励
    vm.startPrank(user1);
    vm.expectRevert("Invalid Merkle proof");
    points.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }

  // 测试事件正确触发
  function test_Events() public {
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));

    // 测试 StateRootUpdated 事件
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));
    vm.startPrank(owner);
    vm.expectEmit(true, false, false, true);
    emit PointsContract.StateRootUpdated(newRoot, block.timestamp);
    points.updateStateRoot(newRoot);
    vm.stopPrank();

    // 重新设置 merkle root 以便测试 PointsClaimed 事件
    vm.startPrank(owner);
    points.updateStateRoot(merkleRoot);
    vm.stopPrank();

    // 测试 PointsClaimed 事件
    vm.startPrank(user1);
    vm.expectEmit(true, true, false, true);
    emit PointsContract.PointsClaimed(user1, claimType, 1000);
    points.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }

  // 测试边界情况：大积分数值
//   function test_ClaimReward_LargePoints() public {
//     // 重新设置包含大积分的 Merkle Tree
//     bytes32 leafLarge = keccak256(abi.encodePacked(user1, uint256(999999999)));
//     bytes32 newRoot = keccak256(abi.encodePacked(leafLarge));
//     bytes32[] memory proofLarge = new bytes32[](1);
//     proofLarge[0] = bytes32(0);

//     vm.startPrank(owner);
//     points.updateStateRoot(newRoot);
//     vm.stopPrank();

//     bytes32 claimType = keccak256(abi.encodePacked("LARGE_POINTS"));

//     vm.startPrank(user1);
//     points.claimReward(user1, 999999999, claimType, proofLarge);
//     vm.stopPrank();

//     assertTrue(points.claimed(user1, claimType));
//   }
}
