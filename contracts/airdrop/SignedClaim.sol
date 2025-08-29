// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title SignedClaim
 * @dev Allows users to claim tokens based on a signature provided by a trusted off-chain backend (oracle).
 * This version includes airdropId and a deadline for enhanced security and tracking.
 */
contract SignedClaim is Ownable, EIP712 {
  IERC20 public immutable token;
  address public signerAddress;

  // Mapping to prevent replay attacks using a user-specific nonce
  mapping(address => uint256) private _nonces;

  event SignerUpdated(address indexed newSigner);
  event Claimed(
    address indexed user,
    uint256 indexed airdropId,
    uint256 amount,
    uint256 nonce
  );

  // EIP712 type hash - UPDATED to include airdropId and deadline
  bytes32 private constant CLAIM_TYPEHASH =
    keccak256(
      "Claim(address userAddress,uint256 airdropId,uint256 amount,uint256 nonce,uint256 deadline)"
    );

  /**
   * @param _tokenAddress The address of the ERC20 token.
   * @param _initialSigner The initial address of the backend signer.
   */
  constructor(
    address _tokenAddress,
    address _initialSigner
  ) EIP712("Arena Airdrop", "1") Ownable(msg.sender) {
    require(_tokenAddress != address(0), "SignedClaim: Invalid token address");
    require(
      _initialSigner != address(0),
      "SignedClaim: Invalid signer address"
    );
    token = IERC20(_tokenAddress);
    signerAddress = _initialSigner;
  }

  /**
   * @dev Allows the owner to update the backend signer address.
   */
  function setSigner(address _newSigner) external onlyOwner {
    require(_newSigner != address(0), "SignedClaim: Invalid signer address");
    signerAddress = _newSigner;
    emit SignerUpdated(_newSigner);
  }

  /**
   * @dev Allows a user to claim tokens with a valid signature from the backend.
   * @param _airdropId An identifier for the specific airdrop campaign.
   * @param _amount The amount of tokens to claim.
   * @param _nonce A unique, sequential number for the user to prevent replay.
   * @param _deadline A timestamp until which the signature is valid.
   * @param _signature The EIP-712 signature from the backend.
   */
  function claim(
    uint256 _airdropId,
    uint256 _amount,
    uint256 _nonce,
    uint256 _deadline,
    bytes calldata _signature
  ) external {
    require(block.timestamp <= _deadline, "SignedClaim: Signature expired");
    require(_nonce == _nonces[msg.sender], "SignedClaim: Invalid nonce");

    // Construct the digest to be verified - UPDATED to match the new structure
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          CLAIM_TYPEHASH,
          msg.sender, // IMPORTANT: The contract uses the actual caller's address
          _airdropId,
          _amount,
          _nonce,
          _deadline
        )
      )
    );

    // Verify the signature
    address recoveredSigner = ECDSA.recover(digest, _signature);
    require(recoveredSigner == signerAddress, "SignedClaim: Invalid signature");

    // Increment nonce to prevent replay of the same signature
    _nonces[msg.sender]++;

    // Transfer tokens
    require(
      token.transfer(msg.sender, _amount),
      "SignedClaim: Token transfer failed"
    );

    emit Claimed(msg.sender, _airdropId, _amount, _nonce);
  }

  /**
   * @dev Returns the current nonce for a user.
   */
  function nonceOf(address _user) public view returns (uint256) {
    return _nonces[_user];
  }
}
