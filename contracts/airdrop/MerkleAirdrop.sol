// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MerkleAirdrop is Ownable {
  IERC20 public immutable token;
  bytes32 public merkleRoot;
  mapping(address => bool) public claimed;

  event AirdropClaimed(address indexed user, uint256 amount);
  event MerkleRootUpdated(bytes32 indexed newRoot);

  constructor(address _token) Ownable(msg.sender) {
    token = IERC20(_token);
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
    emit MerkleRootUpdated(_merkleRoot);
  }

  function claim(uint256 amount, bytes32[] calldata merkleProof) external {
    require(!claimed[msg.sender], "Already claimed");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Invalid proof");

    claimed[msg.sender] = true;
    token.transfer(msg.sender, amount);

    emit AirdropClaimed(msg.sender, amount);
  }
}
