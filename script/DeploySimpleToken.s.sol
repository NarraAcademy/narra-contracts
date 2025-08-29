// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { SimpleToken } from "../contracts/token/SimpleToken.sol";

contract DeploySimpleTokenScript is Script {
  function setUp() public {}

  function run() public {
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    console.log("Deployer address:", deployer);
    console.log("Deployer private key loaded");

    // Token 配置参数
    string memory tokenName = "Ultra Token";
    string memory tokenSymbol = "UTT";
    uint256 initialSupply = 10000000000 * 10 ** 18; // 10000000000 tokens with 18 decimals

    vm.startBroadcast(deployerPrivateKey);

    // 部署 SimpleToken 合约
    SimpleToken token = new SimpleToken(tokenName, tokenSymbol, initialSupply);

    console.log("SimpleToken deployed at:", address(token));

    vm.stopBroadcast();

    // 显示部署后的合约信息
    console.log("=== Deployment Summary ===");
    console.log("Token name:", token.name());
    console.log("Token symbol:", token.symbol());
    console.log("Token decimals:", token.decimals());
    console.log("Initial total supply:", token.totalSupply());
    console.log("Deployer balance:", token.balanceOf(deployer));
    console.log("Contract address:", address(token));
  }
}
