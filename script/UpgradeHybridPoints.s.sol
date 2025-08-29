// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "../lib/forge-std/src/Script.sol";
import { HybridPointsUpgradeable } from "../contracts/checkin/HybridPointsUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract UpgradeHybridPoints is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    // 从环境变量获取代理合约地址
    address proxyAddress = vm.envAddress("PROXY_ADDRESS");

    vm.startBroadcast(deployerPrivateKey);

    console.log("Deployer address:", deployer);
    console.log("Proxy address:", proxyAddress);

    // 1. 部署新的实现合约
    console.log("Deploying new implementation contract...");
    HybridPointsUpgradeable newImplementation = new HybridPointsUpgradeable();
    console.log("New implementation deployed at:", address(newImplementation));

    // 2. 升级代理合约
    console.log("Upgrading proxy contract...");
    // HybridPointsUpgradeable proxy = HybridPointsUpgradeable(proxyAddress);
    (bool success, ) = address(proxyAddress).call(
      abi.encodeWithSignature("upgradeTo(address)", address(newImplementation))
    );
    require(success, "upgradeTo failed");
    console.log("Proxy upgraded successfully!");

    // 3. 验证升级
    // 获取 owner
    (bool ok, bytes memory data) = address(proxyAddress).call(
      abi.encodeWithSignature("owner()")
    );
    require(ok, "owner() call failed");
    address owner = abi.decode(data, (address));
    console.log("Contract owner:", owner);
    // 移除 version 相关输出

    vm.stopBroadcast();

    console.log("\n=== Upgrade Summary ===");
    console.log("New Implementation:", address(newImplementation));
    console.log("Proxy:", proxyAddress);
    console.log("Owner:", deployer);
    console.log("=======================");
  }
}
