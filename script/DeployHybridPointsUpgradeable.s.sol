// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "../lib/forge-std/src/Script.sol";
import { HybridPointsUpgradeable } from "../contracts/HybridPointsUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployHybridPointsUpgradeable is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    vm.startBroadcast(deployerPrivateKey);

    console.log("Deployer address:", deployer);

    // 1. 部署实现合约
    console.log("Deploying implementation contract...");
    HybridPointsUpgradeable implementation = new HybridPointsUpgradeable();
    console.log("Implementation deployed at:", address(implementation));

    // 2. 准备初始化数据
    bytes memory initData = abi.encodeWithSelector(
      HybridPointsUpgradeable.initialize.selector,
      deployer
    );

    // 3. 部署代理合约
    console.log("Deploying proxy contract...");
    ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
    console.log("Proxy deployed at:", address(proxy));

    // 4. 验证部署
    HybridPointsUpgradeable hybridPoints = HybridPointsUpgradeable(
      address(proxy)
    );
    console.log("Contract owner:", hybridPoints.owner());
    // console.log("Contract version:", hybridPoints.version());

    vm.stopBroadcast();

    console.log("\n=== Deployment Summary ===");
    console.log("Implementation:", address(implementation));
    console.log("Proxy:", address(proxy));
    console.log("Owner:", deployer);
    console.log("===========================");
  }
}
