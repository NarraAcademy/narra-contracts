// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { SimplifiedCheckIn } from "../contracts/checkin/SimapleCheckin.sol";

contract DeploySimplifiedCheckInScript is Script {
  function setUp() public {}

  function run() public {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    console.log("Deployer address:", deployer);
    console.log("Deployer private key loaded");

    vm.startBroadcast(deployerPrivateKey);

    // 部署 SimpleCheckIn 合约
    SimplifiedCheckIn checkin = new SimplifiedCheckIn();

    console.log("SimplifiedCheckIn deployed at:", address(checkin));

    vm.stopBroadcast();

    // 显示部署后的合约信息
    console.log("=== Deployment Summary ===");
    console.log("Contract name: SimpleCheckIn");
    console.log("Contract address:", address(checkin));
    console.log("Deployer address:", deployer);

    // 测试获取部署者的用户信息
    (uint256 lastCheckInTime, uint256 totalCheckIns) = checkin.getUserInfo(
      deployer
    );
    console.log("Deployer initial check-in time:", lastCheckInTime);
    console.log("Deployer initial total check-ins:", totalCheckIns);
  }
}
