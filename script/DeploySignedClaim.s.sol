// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { SignedClaim } from "../contracts/airdrop/SignedClaim.sol";
import { SimpleToken } from "../contracts/token/SimpleToken.sol";

contract DeploySignedClaimScript is Script {
  function setUp() public {}

  function run() public {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    console.log("Deployer address:", deployer);
    console.log("Deployer private key loaded");

    // 配置参数
    address tokenAddress = vm.envAddress("TEST_TOKEN_ADDRESS"); // 从环境变量获取代币地址
    address initialSigner = vm.envAddress("TEST_SIGNER_ADDRESS"); // 从环境变量获取签名者地址

    // 如果没有设置环境变量，使用默认值或部署新的代币
    if (tokenAddress == address(0)) {
      console.log("No token address provided, deploying new SimpleToken...");

      vm.startBroadcast(deployerPrivateKey);

      // 部署新的代币合约
      SimpleToken token = new SimpleToken(
        "Arena Token",
        "ARENA",
        1000000000 * 10 ** 18 // 1 billion tokens with 18 decimals
      );

      tokenAddress = address(token);
      console.log("New SimpleToken deployed at:", tokenAddress);

      vm.stopBroadcast();
    }

    if (initialSigner == address(0)) {
      initialSigner = deployer; // 默认使用部署者作为签名者
      console.log(
        "No signer address provided, using deployer as signer:",
        initialSigner
      );
    }

    console.log("=== Deployment Configuration ===");
    console.log("Token address:", tokenAddress);
    console.log("Initial signer:", initialSigner);

    vm.startBroadcast(deployerPrivateKey);

    // 部署 SignedClaim 合约
    SignedClaim signedClaim = new SignedClaim(tokenAddress, initialSigner);

    console.log("SignedClaim deployed at:", address(signedClaim));

    vm.stopBroadcast();

    // 显示部署后的合约信息
    console.log("=== Deployment Summary ===");
    console.log("SignedClaim contract address:", address(signedClaim));
    console.log("Token contract address:", tokenAddress);
    console.log("Signer address:", initialSigner);
    console.log("Owner address:", deployer);

    // 验证部署
    console.log("=== Verification ===");
    console.log(
      "Token balance in SignedClaim:",
      IERC20(tokenAddress).balanceOf(address(signedClaim))
    );
    console.log(
      "Deployer token balance:",
      IERC20(tokenAddress).balanceOf(deployer)
    );
  }
}

// 为了获取代币余额，需要 IERC20 接口
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
}
