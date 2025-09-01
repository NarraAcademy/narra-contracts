# Narra Arena

A blockchain-based arena gaming platform built on BNB Smart Chain (BSC) that enables players to participate in competitive gaming with on-chain rewards and governance.

## Technology Stack

- Blockchain: BNB Smart Chain (BSC)
- Smart Contracts: Solidity ^0.8.0

## Supported Networks
- BNB Smart Chain Testnet (Chain ID: 97)
- BNB Smart Chain Mainnet (Chain ID: 56)

## Contract Addresses

**Checkin Mainnet**: `0x3402F032c4e41303d2158B77391D8b274D97138d`

## Features

- **Check-in Mechanism**: Daily check-in rewards for active users
- **Upgradeable Contracts**: UUPS upgradeable pattern for future improvements
- **Gas Optimization**: Optimized for BSC network with efficient gas usage

## Getting Started

### Prerequisites
- Node.js 18+
- Foundry (forge)
- pnpm

### Installation
```bash
# Clone the repository
git clone https://github.com/NarraAcademy/narra-contracts.git
cd narra-contracts

# Install dependencies
pnpm install

# Install Foundry dependencies
forge install
```

### Development
```bash
# Compile contracts
forge build

# Run tests
forge test
```

## Contract Architecture

- **Checkin**: Daily check-in contract for user engagement
- **NanaAirdrop**: Merkle-based airdrop distribution system