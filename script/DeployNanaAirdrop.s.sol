// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { NanaAirdrop } from "../contracts/airdrop/NanaAirdrop.sol";

contract DeployNanaAirdropScript is Script {
  function setUp() public {}

  function run() public {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    console.log("Deployer address:", deployer);
    console.log("Deployer private key loaded");

    // 配置参数 - 您需要根据实际情况修改这些值
    address tokenAddress = vm.envAddress("TEST_TOKEN_ADDRESS"); // 要空投的代币地址
    address initialOwner = deployer; // 或者设置为其他所有者地址

    console.log("Token address:", tokenAddress);
    console.log("Initial owner:", initialOwner);

    vm.startBroadcast(deployerPrivateKey);

    // 部署 NanaAirdrop 合约
    NanaAirdrop airdrop = new NanaAirdrop(tokenAddress, initialOwner);

    console.log("NanaAirdrop deployed at:", address(airdrop));

    vm.stopBroadcast();

    // 显示部署后的合约信息
    console.log("NanaAirdrop deployed at:", address(airdrop));
    console.log("=== Deployment Summary ===");
    console.log("Airdrop contract address:", address(airdrop));
  }
}
