// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { BurnToStake } from "../contracts/airdrop/BurnToStake.sol";

contract DeployBurnToStakeScript is Script {
  function setUp() public {}

  function run() public {
    // Get deployer private key from environment
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    console.log("Deployer address:", deployer);
    console.log("Deployer private key loaded");

    vm.startBroadcast(deployerPrivateKey);

    // Deploy BurnToStake contract
    BurnToStake burnToStake = new BurnToStake();

    console.log("BurnToStake deployed at:", address(burnToStake));

    vm.stopBroadcast();

    // Display deployment summary
    console.log("=== Deployment Summary ===");
    console.log("BurnToStake contract address:", address(burnToStake));
    console.log("Deployer address:", deployer);
    console.log("Dead address:", burnToStake.DEAD_ADDRESS());
    console.log("Deployment timestamp:", block.timestamp);
  }
}
