// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { CheckInContract } from "../contracts/Checkin.sol";

contract DeployCheckinScript is Script {
  function setUp() public {}

  function run() public {
    // 获取部署者私钥
    uint256 deployerPrivateKey = vm.envUint("DEPLOY_PRIVATE_KEY");

    // 启动广播
    vm.startBroadcast(deployerPrivateKey);

            // 部署 CheckInContract
        CheckInContract checkin = new CheckInContract();

        // 设置 Relayer 地址（这里设置为部署者地址作为示例）
        address relayerAddress = vm.addr(deployerPrivateKey);
        checkin.setRelayer(relayerAddress);

        // 停止广播
        vm.stopBroadcast();

        // 输出部署信息
        console.log("CheckInContract deployed at:", address(checkin));
        console.log("Deployer address:", vm.addr(deployerPrivateKey));
        console.log("Relayer address set to:", relayerAddress);
  }
}
