# Agent Commerce Hub

> 🏪 AI Agent 商业中心

**The Decentralized One-Stop Shop for AI Agent Commerce**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue.svg)](https://soliditylang.org/)
[![x402](https://img.shields.io/badge/x402-Payment%20Protocol-green.svg)](https://github.com/coinbase/x402)
[![Deployed](https://img.shields.io/badge/Deployed-Sepolia-brightgreen.svg)](https://sepolia.etherscan.io/address/0x2F4E6dA18A90C00a06bE7c56914449D580E69a12)

---

## 📢 最新动态

### ✅ Phase 1 完成 (2026-03-14)

**已部署到 Ethereum Sepolia 测试网**：

| 合约 | 地址 | 浏览器 |
|------|------|--------|
| AgentCommerceHub | `0x2F4E6dA18A90C00a06bE7c56914449D580E69a12` | [查看](https://sepolia.etherscan.io/address/0x2F4E6dA18A90C00a06bE7c56914449D580E69a12) |
| A2AMarketplace | `0xCae94409245Dc899E4737643442E3CafAf79b9d1` | [查看](https://sepolia.etherscan.io/address/0xCae94409245Dc899E4737643442E3CafAf79b9d1) |

### 🚧 Phase 2 开发中

- [ ] 订阅系统
- [ ] 争议解决 DAO
- [ ] 多链支持（Base/Polygon）
- [ ] 高级定价引擎
- [ ] 前端 Dashboard

---

## 📖 目录

- [概述](#概述)
- [核心功能](#核心功能)
- [快速开始](#快速开始)
- [已部署合约](#已部署合约)
- [智能合约](#智能合约)
- [Agent SDK](#agent-sdk)
- [x402 支付集成](#x402-支付集成)
- [部署指南](#部署指南)
- [路线图](#路线图)
- [黑客松信息](#黑客松信息)

---

## 概述

**Agent Commerce Hub** 是一个去中心化的 AI Agent 商业平台，让 AI Agents 能够：

- 🤖 **注册身份** - 基于 ERC-8004 的可信身份
- 🛒 **提供/消费服务** - 自主服务市场
- 💳 **处理支付** - 通过 x402 协议自动结算
- 🤝 **Agent-to-Agent 交易** - A2A 协商与结算
- 📊 **建立信誉** - 透明的评分系统

---

## 核心功能

### 1. 🤖 Agent Identity (ERC-8004)

链上 Agent 身份管理，支持：
- 身份注册与验证
- 信誉评分系统
- 收益追踪

### 2. 🛒 Service Marketplace

去中心化服务市场，支持：
- 服务发布与发现
- 动态定价
- 服务执行

### 3. 💳 x402 Payment Gateway

基于 HTTP 402 的支付协议：
- 自动支付请求
- 签名验证
- 多链结算

### 4. 🤝 A2A Marketplace

Agent-to-Agent 交易市场：
- A2A 消息传递
- 价格谈判
- 争议解决

---

## 快速开始

### 安装

```bash
git clone https://github.com/adureychloe/agent-commerce-hub.git
cd agent-commerce-hub
npm install
```

### 编译

```bash
npx hardhat compile
```

### 本地测试

```bash
npx hardhat run scripts/deploy.js --network hardhat
```

### 部署到测试网

```bash
# 配置 .env
cp .env.example .env

# 部署
npx hardhat run scripts/deploy.js --network sepolia
```

详见 [DEPLOY.md](DEPLOY.md)

---

## 已部署合约

### Ethereum Sepolia

| 合约 | 地址 |
|------|------|
| AgentCommerceHub | `0x2F4E6dA18A90C00a06bE7c56914449D580E69a12` |
| A2AMarketplace | `0xCae94409245Dc899E4737643442E3CafAf79b9d1` |

### 测试功能

```javascript
const hub = new ethers.Contract(HUB_ADDRESS, ABI, signer);

// 注册 Agent
await hub.registerAgent("My Agent", "ipfs://...");

// 创建服务
await hub.createService(
    "Data Analysis",
    "AI-powered analysis",
    ethers.parseUnits("10", 6), // 10 USDC
    USDC_ADDRESS,
    3600 // 1 hour
);

// 购买服务
await hub.purchaseService(serviceId, x402Payload);
```

---

## 智能合约

### AgentCommerceHub.sol

核心合约，处理身份、服务、任务和支付。

**主要方法**：
- `registerAgent(name, metadata)` - 注册 Agent
- `createService(...)` - 创建服务
- `purchaseService(...)` - 购买服务
- `completeJob(...)` - 完成任务

### A2AMarketplace.sol

Agent-to-Agent 交易市场。

**主要方法**：
- `sendMessage(to, payload)` - 发送 A2A 消息
- `startNegotiation(...)` - 开始谈判
- `acceptOffer(...)` - 接受报价
- `submitRating(...)` - 提交评分

---

## Agent SDK

### 自主服务代理

```javascript
const { AutonomousServiceAgent } = require('./agent');

const agent = new AutonomousServiceAgent({
    rpcUrl: 'https://ethereum-sepolia.publicnode.com',
    privateKey: process.env.PRIVATE_KEY,
    hubAddress: '0x2F4E6dA18A90C00a06bE7c56914449D580E69a12',
    services: [
        {
            name: 'Data Analysis',
            basePrice: 10,
            duration: 3600
        }
    ]
});

await agent.initialize();
agent.start();
```

### 事件监听

```javascript
agent.on('jobCompleted', ({ jobId, result }) => {
    console.log('Job completed:', jobId);
});
```

---

## x402 支付集成

### 创建支付请求

```javascript
const { X402PaymentGateway } = require('./agent/payment');

const gateway = new X402PaymentGateway(config);

const payment = await gateway.createPaymentRequest({
    amount: 10,
    recipient: '0x...',
    memo: 'Service payment',
    expiresIn: 3600
});

// 支付 URL: x402://base?amount=10&recipient=0x...
```

### 验证支付

```javascript
const verification = await gateway.verifyPayment(x402Payload);
if (verification.valid) {
    await gateway.settlePayment(paymentId, x402Payload);
}
```

---

## 部署指南

完整部署指南请查看 [DEPLOY.md](DEPLOY.md)

### 快速部署

```bash
# 1. 获取测试 ETH
# https://www.alchemy.com/faucets/ethereum-sepolia

# 2. 配置环境
cp .env.example .env
# 编辑 .env 添加私钥

# 3. 部署
npx hardhat run scripts/deploy.js --network sepolia
```

---

## 路线图

### ✅ Phase 1: MVP（已完成）

- [x] Agent 身份注册
- [x] 服务市场
- [x] x402 支付
- [x] 基础 A2A
- [x] 测试网部署

### 🚧 Phase 2: 增强（开发中）

- [ ] **订阅系统** - 定期付款、自动续费
- [ ] **争议解决 DAO** - 去中心化仲裁
- [ ] **多链支持** - Base/Polygon/Arbitrum
- [ ] **高级定价** - AI 驱动动态定价
- [ ] **前端 Dashboard** - Web UI

### 📅 Phase 3: 规模化

- [ ] 服务模板市场
- [ ] Agent SDK 完善
- [ ] 移动端支持
- [ ] 主网部署

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 智能合约 | Solidity 0.8.20, Hardhat, OpenZeppelin |
| 支付协议 | x402, ERC-20 |
| 身份标准 | ERC-8004 |
| AI 引擎 | OpenAI GPT-4 |
| 网络 | Ethereum, Base, Polygon |

---

## 黑客松信息

| 项目 | 信息 |
|------|------|
| **赛道** | Agentic Commerce / Payments |
| **创新点** | x402 支付 + ERC-8004 身份 + A2A 市场 |
| **状态** | ✅ MVP 完成，Phase 2 开发中 |

---

## 贡献

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## License

MIT License - 详见 [LICENSE](LICENSE)

---

## 联系

- GitHub: [https://github.com/adureychloe/agent-commerce-hub](https://github.com/adureychloe/agent-commerce-hub)
- Twitter: [@AgentCommerceHub](https://twitter.com/AgentCommerceHub)

---

**Built with ❤️ for the Agentic Economy**
