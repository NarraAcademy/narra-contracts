// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Airdrop
 * @dev A contract for distributing ERC20 tokens via a Merkle Tree airdrop.
 * Includes features for updating the airdrop data, transferring ownership,
 * and withdrawing leftover tokens by the owner.
 */
contract NanaAirdrop is Ownable {
  IERC20 public immutable token;

  bytes32 public merkleRoot;

  mapping(address => uint256) public totalClaimed;

  event Claimed(address indexed user, uint256 amount);
  event MerkleRootUpdated(bytes32 indexed newRoot);
  event TokensWithdrawn(address indexed to, uint256 amount);

  /**
   * @dev Sets the token to be airdropped and the initial owner.
   * @param _tokenAddress The address of the ERC20 token.
   * @param initialOwner The initial owner of the contract.
   */
  constructor(
    address _tokenAddress,
    address initialOwner
  ) Ownable(initialOwner) {
    require(
      _tokenAddress != address(0),
      "Airdrop: Token address cannot be zero"
    );
    token = IERC20(_tokenAddress);
  }

  /**
   * @dev Owner can set a new Merkle root to start a new airdrop period.
   * @param _merkleRoot The new Merkle root.
   */
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
    emit MerkleRootUpdated(_merkleRoot);
  }

  /**
   * @dev Users claim their airdropped tokens.
   * @param totalClaimableAmount The total cumulative amount the user is eligible for.
   * @param merkleProof The Merkle proof to verify the user's eligibility.
   */
  function claim(
    uint256 totalClaimableAmount,
    bytes32[] calldata merkleProof
  ) external {
    require(merkleRoot != bytes32(0), "Airdrop: No active airdrop");

    uint256 amountToClaim = totalClaimableAmount - totalClaimed[msg.sender];
    require(amountToClaim > 0, "Airdrop: Nothing to claim or already claimed");

    bytes32 leaf = keccak256(
      abi.encodePacked(msg.sender, totalClaimableAmount)
    );

    require(
      MerkleProof.verify(merkleProof, merkleRoot, leaf),
      "Airdrop: Invalid proof"
    );

    totalClaimed[msg.sender] = totalClaimableAmount;

    require(
      token.balanceOf(address(this)) >= amountToClaim,
      "Airdrop: Insufficient contract balance"
    );
    require(
      token.transfer(msg.sender, amountToClaim),
      "Airdrop: Token transfer failed"
    );

    emit Claimed(msg.sender, amountToClaim);
  }

  /**
   * @dev Allows the owner to withdraw remaining tokens from the contract.
   * This is useful for retrieving leftover tokens after an airdrop is complete.
   */
  function withdrawTokens() public onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance > 0, "Airdrop: No tokens to withdraw");

    require(
      token.transfer(owner(), balance),
      "Airdrop: Withdrawal transfer failed"
    );

    emit TokensWithdrawn(owner(), balance);
  }

  // /**
  //  * @dev Verify if a user is eligible for claiming tokens with the given amount.
  //  * This is a view function that can be called without gas cost for verification purposes.
  //  * @param user The address of the user to verify.
  //  * @param totalClaimableAmount The total cumulative amount the user claims to be eligible for.
  //  * @param merkleProof The Merkle proof to verify the user's eligibility.
  //  * @return bool Returns true if the proof is valid, false otherwise.
  //  */
  // function verifyClaim(
  //   address user,
  //   uint256 totalClaimableAmount,
  //   bytes32[] calldata merkleProof
  // ) public view returns (bool) {
  //   if (merkleRoot == bytes32(0)) {
  //     return false;
  //   }

  //   bytes32 leaf = keccak256(abi.encodePacked(user, totalClaimableAmount));

  //   return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  // }

  // /**
  //  * @dev Get the leaf hash for a given user and amount.
  //  * This is useful for debugging and generating merkle proofs.
  //  * @param user The address of the user.
  //  * @param totalClaimableAmount The total cumulative amount the user is eligible for.
  //  * @return bytes32 The leaf hash that should be included in the merkle tree.
  //  */
  // function getLeafHash(
  //   address user,
  //   uint256 totalClaimableAmount
  // ) public pure returns (bytes32) {
  //   return keccak256(abi.encodePacked(user, totalClaimableAmount));
  // }
}
