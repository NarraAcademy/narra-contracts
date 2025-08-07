// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console } from "../lib/forge-std/src/Test.sol";
import { HybridPointsUpgradeable } from "../contracts/HybridPointsUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract HybridPointsUpgradeableTest is Test {
  HybridPointsUpgradeable public implementation;
  HybridPointsUpgradeable public hybridPoints;
  ERC1967Proxy public proxy;

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

    // 部署实现合约
    implementation = new HybridPointsUpgradeable();

    // 准备初始化数据
    bytes memory initData = abi.encodeWithSelector(
      HybridPointsUpgradeable.initialize.selector
    );

    // 部署代理合约
    proxy = new ERC1967Proxy(address(implementation), initData);

    // 通过代理地址创建合约实例
    hybridPoints = HybridPointsUpgradeable(address(proxy));

    // 获取实际的 owner（部署者）
    (bool ok, bytes memory data) = address(hybridPoints).call(
      abi.encodeWithSignature("owner()")
    );
    require(ok, "owner() call failed");
    address actualOwner = abi.decode(data, (address));

    // 更新 owner 为实际的合约 owner
    owner = actualOwner;

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
  // 基础功能测试
  // =================================================================

  function test_Initialization() public view {
    assertEq(hybridPoints.owner(), owner);
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

  function test_GetCheckInDigest() public view {
    uint256 dailyNonce = 20240520;
    // 通过接口调用 getCheckInDigest
    bytes32 digest = HybridPointsUpgradeable(address(hybridPoints))
      .getCheckInDigest(user1, dailyNonce);
    // 验证 digest 不为零
    assertTrue(digest != bytes32(0));
  }

  // =================================================================
  // 升级功能测试
  // =================================================================

  function test_UpgradeContract() public {
    // 部署新的实现合约
    HybridPointsUpgradeable newImplementation = new HybridPointsUpgradeable();

    // 升级代理合约
    vm.startPrank(owner);
    (bool success, ) = address(hybridPoints).call(
      abi.encodeWithSignature("upgradeTo(address)", address(newImplementation))
    );
    require(success, "upgradeTo failed");
    vm.stopPrank();

    // 验证升级后功能仍然正常
    assertEq(hybridPoints.owner(), owner);
    assertEq(hybridPoints.merkleRoot(), merkleRoot);
  }

  function test_UpgradeContract_Unauthorized() public {
    // 部署新的实现合约
    HybridPointsUpgradeable newImplementation = new HybridPointsUpgradeable();

    // 非 owner 尝试升级
    vm.startPrank(user1);
    (bool success, ) = address(hybridPoints).call(
      abi.encodeWithSignature("upgradeTo(address)", address(newImplementation))
    );
    assertTrue(!success, "upgradeTo should fail for non-owner");
    vm.stopPrank();
  }

  function test_UpgradeAndClaimReward() public {
    // 先领取一个奖励
    bytes32 claimType = keccak256(abi.encodePacked("NFT_SKIN_1"));
    vm.startPrank(user1);
    hybridPoints.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();

    // 升级合约
    HybridPointsUpgradeable newImplementation = new HybridPointsUpgradeable();
    vm.startPrank(owner);
    (bool success, ) = address(hybridPoints).call(
      abi.encodeWithSignature("upgradeTo(address)", address(newImplementation))
    );
    require(success, "upgradeTo failed");
    vm.stopPrank();

    // 验证升级后状态保持不变
    assertTrue(hybridPoints.claimed(user1, claimType));
    assertEq(hybridPoints.merkleRoot(), merkleRoot);
  }

  // =================================================================
  // 事件测试
  // =================================================================

  function test_Events() public {
    // 测试 StateRootUpdated 事件
    bytes32 newRoot = keccak256(abi.encodePacked("new_root"));
    vm.startPrank(owner);
    vm.expectEmit(true, false, false, true);
    emit HybridPointsUpgradeable.StateRootUpdated(newRoot);
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
    emit HybridPointsUpgradeable.PointsClaimed(user1, claimType, 1000);
    hybridPoints.claimReward(user1, 1000, claimType, proof1);
    vm.stopPrank();
  }
}
