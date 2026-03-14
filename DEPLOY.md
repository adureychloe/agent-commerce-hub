# 部署指南

## 目录

- [环境准备](#环境准备)
- [本地测试](#本地测试)
- [测试网部署](#测试网部署)
- [主网部署](#主网部署)
- [验证合约](#验证合约)
- [常见问题](#常见问题)

---

## 环境准备

### 1. 安装依赖

```bash
git clone https://github.com/adureychloe/agent-commerce-hub.git
cd agent-commerce-hub
npm install
```

### 2. 编译合约

```bash
npx hardhat compile
```

输出：
```
Compiled 12 Solidity files successfully
```

### 3. 配置环境变量

复制示例配置：
```bash
cp .env.example .env
```

编辑 `.env`：
```env
# Ethereum Sepolia 测试网
SEPOLIA_RPC_URL=https://ethereum-sepolia.publicnode.com
PRIVATE_KEY=你的私钥

# Base Sepolia 测试网
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org

# OpenAI API Key
OPENAI_KEY=sk-...
```

---

## 本地测试

### 快速测试（无需真实 ETH）

```bash
npx hardhat run scripts/deploy.js --network hardhat
```

输出：
```
🚀 Deploying Agent Commerce Hub...

📦 Deploying AgentCommerceHub...
   ✅ AgentCommerceHub: 0x5FbDB2315678afecb367f032d93F642f64180aa3

📦 Deploying A2AMarketplace...
   ✅ A2AMarketplace: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

✅ All tests passed!
```

### 运行单元测试

```bash
npx hardhat test
```

---

## 测试网部署

### 步骤 1: 获取测试 ETH

#### Ethereum Sepolia

1. **Alchemy Faucet**: https://www.alchemy.com/faucets/ethereum-sepolia
2. **Infura Faucet**: https://www.infura.io/faucet/sepolia
3. **Google Cloud Faucet**: https://cloud.google.com/application/web3/faucet/ethereum/sepolia

需要 ~0.002 ETH 部署两个合约。

#### Base Sepolia

1. **Circle Faucet**: https://faucet.circle.com/ (选择 Base Sepolia)
2. **Base Faucet**: https://base.org/faucet

### 步骤 2: 检查余额

```bash
node -e "
const { ethers } = require('ethers');
const provider = new ethers.JsonRpcProvider('https://ethereum-sepolia.publicnode.com');
const address = '你的钱包地址';
provider.getBalance(address).then(b => console.log('Balance:', ethers.formatEther(b), 'ETH'));
"
```

### 步骤 3: 部署合约

#### Ethereum Sepolia

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

#### Base Sepolia

```bash
npx hardhat run scripts/deploy.js --network base_sepolia
```

### 步骤 4: 记录合约地址

部署成功后，会输出：

```
══════════════════════════════════════════════════
📋 Deployment Summary
══════════════════════════════════════════════════
Network: sepolia
Deployer: 0x98fC8f59d4C308990772A94E6F079A4891682BDA
AgentCommerceHub: 0x2F4E6dA18A90C00a06bE7c56914449D580E69a12
A2AMarketplace: 0xCae94409245Dc899E4737643442E3CafAf79b9d1
══════════════════════════════════════════════════
```

**重要**: 保存这些地址到 `.env`：

```env
HUB_CONTRACT=0x2F4E6dA18A90C00a06bE7c56914449D580E69a12
A2A_CONTRACT=0xCae94409245Dc899E4737643442E3CafAf79b9d1
```

---

## 主网部署

### ⚠️ 警告

主网部署需要真实 ETH，请确保：
- 部署前在测试网充分测试
- 审计合约代码
- 了解 Gas 费用
- 准备足够的 ETH（~0.01-0.02 ETH）

### 步骤 1: 配置主网

编辑 `.env`：

```env
# Ethereum Mainnet
MAINNET_RPC_URL=https://ethereum.publicnode.com
PRIVATE_KEY=你的主网私钥

# Base Mainnet
BASE_RPC_URL=https://mainnet.base.org
```

编辑 `hardhat.config.js`：

```javascript
networks: {
  mainnet: {
    url: process.env.MAINNET_RPC_URL,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    chainId: 1
  },
  base: {
    url: process.env.BASE_RPC_URL,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    chainId: 8453
  }
}
```

### 步骤 2: 估算 Gas

```bash
npx hardhat run scripts/estimate-gas.js --network mainnet
```

### 步骤 3: 部署

```bash
# Ethereum Mainnet
npx hardhat run scripts/deploy.js --network mainnet

# Base Mainnet
npx hardhat run scripts/deploy.js --network base
```

---

## 验证合约

### 自动验证（需要 API Key）

1. 获取 Etherscan API Key: https://etherscan.io/myapikey
2. 添加到 `.env`：

```env
ETHERSCAN_API_KEY=你的API密钥
```

3. 验证合约：

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

示例：
```bash
npx hardhat verify --network sepolia 0x2F4E6dA18A90C00a06bE7c56914449D580E69a12 0x98fC8f59d4C308990772A94E6F079A4891682BDA
```

### 手动验证

1. 访问区块浏览器：
   - Ethereum Sepolia: https://sepolia.etherscan.io
   - Base Sepolia: https://sepolia.basescan.org

2. 点击 "Verify and Publish"
3. 选择 "Solidity (Single file)" 或 "Solidity (Standard-Json-Input)"
4. 上传合约源码
5. 点击 "Verify"

---

## 部署后配置

### 1. 授权 USDC

如果使用 USDC 支付：

```javascript
// 在脚本中或通过 Etherscan
await hub.authorizeToken(USDC_ADDRESS);
```

### 2. 设置平台费用

```javascript
await hub.setPlatformFee(250); // 2.5%
```

### 3. 验证 Agent（管理员）

```javascript
await hub.verifyAgent(agentAddress);
```

---

## 网络信息

### Ethereum Sepolia

| 项目 | 值 |
|------|-----|
| Chain ID | 11155111 |
| RPC | https://ethereum-sepolia.publicnode.com |
| Explorer | https://sepolia.etherscan.io |
| Faucet | https://www.alchemy.com/faucets/ethereum-sepolia |

### Base Sepolia

| 项目 | 值 |
|------|-----|
| Chain ID | 84532 |
| RPC | https://sepolia.base.org |
| Explorer | https://sepolia.basescan.org |
| Faucet | https://faucet.circle.com |
| USDC | 0x036CbD53842c5426634e7929541eC2318f3dCF7e |

### Base Mainnet

| 项目 | 值 |
|------|-----|
| Chain ID | 8453 |
| RPC | https://mainnet.base.org |
| Explorer | https://basescan.org |
| USDC | 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 |

---

## 费用估算

### 测试网（免费）

| 网络 | 部署费用 |
|------|----------|
| Hardhat | 0 ETH |
| Sepolia | ~0.002 ETH（测试 ETH） |
| Base Sepolia | ~0.001 ETH（测试 ETH） |

### 主网（真实 ETH）

| 合约 | Gas | 费用（50 Gwei） |
|------|-----|-----------------|
| AgentCommerceHub | ~2,000,000 | ~0.1 ETH |
| A2AMarketplace | ~1,500,000 | ~0.075 ETH |
| **总计** | ~3,500,000 | **~0.175 ETH** |

**注意**: Gas 价格波动，实际费用可能不同。

---

## 常见问题

### Q: 部署失败 "insufficient funds"

**A**: 钱包 ETH 不足。获取更多测试 ETH 或主网 ETH。

### Q: 部署超时 "Headers Timeout Error"

**A**: RPC 节点响应慢。尝试其他 RPC：
- https://ethereum-sepolia.publicnode.com
- https://rpc.sepolia.org
- https://ethereum-sepolia.blockpi.network/v1/rpc/public

### Q: 如何查看交易详情？

**A**: 在区块浏览器输入交易哈希或合约地址。

### Q: 如何更新合约？

**A**: 使用代理模式（UUPS 或 Transparent）实现可升级合约。

### Q: 私钥泄露了怎么办？

**A**: 立即转移所有资产到新钱包。测试网私钥泄露风险较低，但建议重新生成。

---

## 部署清单

部署前检查：

- [ ] 安装依赖 `npm install`
- [ ] 编译合约 `npx hardhat compile`
- [ ] 配置 `.env` 文件
- [ ] 获取测试 ETH（测试网）
- [ ] 检查余额足够
- [ ] 运行本地测试
- [ ] 部署到测试网
- [ ] 验证合约功能
- [ ] 记录合约地址
- [ ] 提交代码到 Git

---

## 联系支持

遇到问题？
- GitHub Issues: https://github.com/adureychloe/agent-commerce-hub/issues
- Discord: [Join our community](https://discord.gg/agentcommerce)

---

**最后更新**: 2026-03-14
