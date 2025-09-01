import "@nomicfoundation/hardhat-toolbox-viem";
import "hardhat-deploy";
import type { HardhatUserConfig } from "hardhat/config";
import { vars } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { ChainId, getChainConfig } from "./src/enum/chains";

// This project is deployed on BNB Smart Chain (BSC).
// Keywords for DAppBay: BNB, BNB Chain, BSC, BNB Smart Chain, opBNB, Greenfield.

import "./tasks/accounts";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

const envFiles = [".env.local", ".env.development", ".env.test", ".env"];

envFiles.forEach(envFile => {
  const envPath = resolve(__dirname, envFile);
  try {
    dotenvConfig({ path: envPath });
    console.log(`Loaded environment from: ${envFile}`);
  } catch (error) {}
});

const mnemonic: string = process.env.MNEMONIC || vars.get("MNEMONIC", "");

function makeNetworkConfig(chainId: ChainId): NetworkUserConfig {
  const chain = getChainConfig(chainId);
  return {
    url: chain.rpcUrl,
    chainId: chain.id,
    accounts: {
      mnemonic,
      count: 10,
      path: "m/44'/60'/0'/0",
    },
  };
}

const config: HardhatUserConfig = {
  namedAccounts: {
    deployer: 0,
  },
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      { version: "0.8.19" },
      { version: "0.8.20" },
      { version: "0.8.28" },
    ],
    settings: {
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 800,
      },
    },
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: 31337,
    },
    mainnet: makeNetworkConfig(ChainId.ETH_MAINNET),
    sepolia: makeNetworkConfig(ChainId.ETH_SEPOLIA),
    bsc: makeNetworkConfig(ChainId.BSC_MAINNET),
    arbitrum: makeNetworkConfig(ChainId.ARBITRUM_MAINNET),
    optimism: makeNetworkConfig(ChainId.OPTIMISM_MAINNET),
  },
  etherscan: {
    apiKey: {
      arbitrumOne:
        process.env.ARBISCAN_API_KEY || vars.get("ARBISCAN_API_KEY", ""),
      bsc: process.env.BSCSCAN_API_KEY || vars.get("BSCSCAN_API_KEY", ""),
      mainnet:
        process.env.ETHERSCAN_API_KEY || vars.get("ETHERSCAN_API_KEY", ""),
      optimisticEthereum:
        process.env.OPTIMISM_API_KEY || vars.get("OPTIMISM_API_KEY", ""),
      sepolia:
        process.env.ETHERSCAN_API_KEY || vars.get("ETHERSCAN_API_KEY", ""),
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
};

export default config;
