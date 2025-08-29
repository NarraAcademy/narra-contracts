// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { TestToken } from "../contracts/token/TestToken.sol";

contract DeployTestTokenScript is Script {
  function setUp() public {}

  function run() public {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    console.log("...deployer:", deployer);
    console.log("...deployerPrivateKey:", deployerPrivateKey);

    vm.startBroadcast(deployerPrivateKey);

    // 部署 TestToken 合约
    TestToken token = new TestToken("Test Token", "TT");

    console.log("TestToken deployed:", address(token));

    vm.stopBroadcast();

    // 显示合约信息
    console.log("token name:", token.name());
    console.log("token symbol:", token.symbol());
    console.log("token decimals:", token.decimals());
    console.log("token totalSupply:", token.totalSupply());
    console.log("deployer balance:", token.balanceOf(deployer));
  }
}
