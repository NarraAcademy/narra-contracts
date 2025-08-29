// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 导入 OpenZeppelin 专门为可升级合约设计的库
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// 修正: 直接导入标准的、无状态的库
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title HybridPointsUpgradeable
 * @dev HybridPointsContract 的可升级版本。
 * - 使用 initializer 函数替代 constructor。
 * - 导入的库都是 -upgradeable 版本。
 * - 部署时应使用 OpenZeppelin Upgrades 插件和代理模式。
 */
contract HybridPointsUpgradeable is
  Initializable,
  OwnableUpgradeable,
  EIP712Upgradeable,
  UUPSUpgradeable
{
  // 定义用于批量签到的数据结构
  struct CheckInData {
    address user;
    uint256 dailyNonce;
    bytes signature;
  }

  // --- 状态变量 (State Variables) ---
  bytes32 public merkleRoot;
  mapping(address => mapping(bytes32 => bool)) public claimed;
  mapping(address => mapping(uint256 => bool)) public hasCheckedIn;

  // --- 事件 (Events) ---
  event StateRootUpdated(bytes32 indexed newRoot);
  event PointsClaimed(
    address indexed user,
    bytes32 indexed claimType,
    uint256 points
  );
  event UserCheckedIn(address indexed user, uint256 indexed dailyNonce);

  // --- EIP712 ---
  bytes32 private constant CHECKIN_TYPEHASH =
    keccak256("CheckIn(address user,uint256 dailyNonce)");

  /**
   * @dev 初始化函数，替代了构造函数。
   */
  function initialize() public initializer {
    __EIP712_init("HybridPointsContract", "1");
    __Ownable_init(msg.sender);
    __UUPSUpgradeable_init();
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
    // 修正: 调用标准库函数
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

  function batchCheckIn(CheckInData[] calldata checkIns) public onlyOwner {
    for (uint256 i = 0; i < checkIns.length; i++) {
      address user = checkIns[i].user;
      uint256 nonce = checkIns[i].dailyNonce;

      if (!hasCheckedIn[user][nonce]) {
        bytes32 structHash = keccak256(
          abi.encode(CHECKIN_TYPEHASH, user, nonce)
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        // 修正: 调用标准库函数
        address signer = ECDSA.recover(digest, checkIns[i].signature);

        if (signer == user && signer != address(0)) {
          hasCheckedIn[user][nonce] = true;
          emit UserCheckedIn(user, nonce);
        }
      }
    }
  }

  function getCheckInDigest(
    address user,
    uint256 dailyNonce
  ) public view returns (bytes32) {
    bytes32 structHash = keccak256(
      abi.encode(CHECKIN_TYPEHASH, user, dailyNonce)
    );
    return _hashTypedDataV4(structHash);
  }

  /**
   * @dev 授权升级函数，只有 owner 可以升级合约
   */
  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}

  /**
   * @dev 为未来的升级保留存储插槽，防止存储布局冲突。
   */
  uint256[49] private __gap;
}
