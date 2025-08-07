# HybridPoints 可升级合约使用指南

## 概述

`HybridPointsUpgradeable.sol` 是一个支持 UUPS (Universal Upgradeable Proxy Standard) 的可升级智能合约，结合了批量签到和 Merkle 积分系统。

## 文件结构

```
contracts/
├── HybridPoints.sol              # 原始不可升级版本
└── HybridPointsUpgradeable.sol   # 可升级版本

script/
├── DeployHybridPointsUpgradeable.s.sol  # 部署脚本
└── UpgradeHybridPoints.s.sol            # 升级脚本

foundry_test/
└── HybridPointsUpgradeable.t.sol        # 可升级合约测试
```

## 部署流程

### 1. 首次部署

```bash
# 设置环境变量
export PRIVATE_KEY="你的私钥"

# 部署可升级合约
forge script script/DeployHybridPointsUpgradeable.s.sol --rpc-url <RPC_URL> --broadcast
```

部署后会输出：
- Implementation 地址：实现合约地址
- Proxy 地址：代理合约地址（这是用户交互的地址）
- Owner：合约所有者

### 2. 合约升级

```bash
# 设置环境变量
export PRIVATE_KEY="你的私钥"
export PROXY_ADDRESS="代理合约地址"

# 升级合约
forge script script/UpgradeHybridPoints.s.sol --rpc-url <RPC_URL> --broadcast
```

## 测试

```bash
# 运行可升级合约测试
forge test --match-contract HybridPointsUpgradeableTest -vv
```

## 关键特性

### 1. UUPS 可升级模式
- 使用 OpenZeppelin 的 UUPS 标准
- 只有 owner 可以升级合约
- 升级后状态保持不变

### 2. 初始化函数
```solidity
function initialize(address initialOwner) public initializer
```
- 替代构造函数
- 设置初始所有者
- 初始化 EIP712 和 UUPS

### 3. 升级授权
```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner
```
- 只有 owner 可以升级
- 防止未授权升级

### 4. 版本管理
```solidity
function version() public pure returns (string memory)
```
- 返回合约版本号
- 便于版本追踪

## 升级注意事项

### 1. 存储布局
- **重要**：升级时不能修改现有存储变量的布局
- 新变量只能添加到存储布局的末尾
- 不能删除或重新排列现有变量

### 2. 函数签名
- 不能删除或修改现有函数的签名
- 可以添加新函数
- 可以修改函数内部逻辑

### 3. 事件
- 不能删除现有事件
- 可以添加新事件

### 4. 状态变量
```solidity
// ✅ 正确：添加新变量到末尾
mapping(address => uint256) public newVariable;

// ❌ 错误：修改现有变量
// uint256 public merkleRoot; // 不能改为 uint256
```

## 最佳实践

### 1. 升级前测试
```bash
# 在测试网升级前充分测试
forge test --match-contract HybridPointsUpgradeableTest
```

### 2. 备份状态
- 升级前记录重要状态
- 验证升级后状态正确

### 3. 分阶段升级
- 先在测试网升级
- 验证功能正常后再在主网升级

### 4. 多签升级
- 考虑使用多签钱包作为 owner
- 增加升级安全性

## 与不可升级版本的区别

| 特性     | 不可升级版本 | 可升级版本       |
| -------- | ------------ | ---------------- |
| 部署     | 直接部署     | 代理 + 实现      |
| 升级     | 不支持       | 支持 UUPS 升级   |
| 存储     | 直接存储     | 通过代理存储     |
| Gas 成本 | 较低         | 稍高（代理调用） |
| 复杂性   | 简单         | 较复杂           |

## 故障排除

### 1. 升级失败
- 检查是否为 owner
- 验证新实现合约正确
- 检查存储布局兼容性

### 2. 初始化失败
- 确保只初始化一次
- 检查初始化参数正确

### 3. 状态丢失
- 验证代理地址正确
- 检查存储变量布局

## 示例升级场景

### 场景 1：添加新功能
```solidity
// 在合约末尾添加新变量和函数
mapping(address => uint256) public userLevel;

function setUserLevel(address user, uint256 level) public onlyOwner {
    userLevel[user] = level;
}
```

### 场景 2：修改逻辑
```solidity
// 修改现有函数内部逻辑
function claimReward(...) public {
    // 添加新的验证逻辑
    require(userLevel[user] >= 1, "Level too low");
    
    // 原有逻辑保持不变
    require(msg.sender == user, "Caller is not the user");
    // ...
}
```

## 安全建议

1. **权限管理**：定期审查 owner 权限
2. **升级测试**：每次升级前充分测试
3. **备份策略**：维护合约状态备份
4. **监控**：监控升级事件和异常
5. **文档**：维护详细的升级记录 