// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { BatchSender } from "../contracts/airdrop/BatchSender.sol";

contract DeployBatchSenderScript is Script {
  function setUp() public {}

  function run() public {
    // 获取部署者私钥
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    console.log("Deployer address:", deployer);
    console.log("Deployer private key loaded");

    // 从环境变量获取管理员地址，如果没有设置则使用部署者地址
    address adminAddress;
    try vm.envAddress("ADMIN_ADDRESS") {
      adminAddress = vm.envAddress("ADMIN_ADDRESS");
    } catch {
      adminAddress = deployer;
      console.log("ADMIN_ADDRESS not set, using deployer as admin");
    }

    console.log("Admin address:", adminAddress);

    vm.startBroadcast(deployerPrivateKey);

    // 部署 BatchSender 合约
    BatchSender batchSender = new BatchSender(adminAddress);

    console.log("BatchSender deployed at:", address(batchSender));

    vm.stopBroadcast();

    // 显示部署后的合约信息
    console.log("=== Deployment Summary ===");
    console.log("BatchSender contract address:", address(batchSender));
    console.log("Robot address (owner):", batchSender.owner());
    console.log("Admin address:", batchSender.admin());
    console.log("Deployer address:", deployer);

    // 验证权限设置
    console.log("=== Permission Verification ===");
    console.log(
      "Is deployer the robot (owner)?",
      batchSender.owner() == deployer
    );
    console.log(
      "Is admin address set correctly?",
      batchSender.admin() == adminAddress
    );

    console.log("=== Usage Instructions ===");
    console.log(
      "1. Robot (owner) can call batchSend() to send tokens to multiple addresses"
    );
    console.log(
      "2. Admin can call withdrawEther(), withdrawTokens(), withdrawTokensAmount()"
    );
    console.log("3. Owner can call setAdmin() to change admin address");
    console.log(
      "4. Contract must be pre-funded with ERC20 tokens before batchSend()"
    );
  }
}
