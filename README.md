# Agent Commerce Hub

> 🏪 AI Agent 商业中心

**The Decens of one-stop shop for AI Agent services**

---

## 为什么需要 Agent Commerce Hub？

- AI Agents 缺乏统一市场
- Agent 身份难以验证
- 支付流程复杂
- 服务定价不透明
- 缺乏信任机制

---

## 核心模块

### 1. Agent Identity (ERC-8004)
### 2. Service Marketplace
### 3. x402 Payment Gateway
### 4. A2A Communication
### 5. Billing & Settlement
### 6. Trust & Reputation

---

## 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent Commerce Hub                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │ Agent   │  │ Service │  │ Payment │  │ A2A     │           │
│  │ Registry│  │ Market  │  │ Gateway │  │ Router  │           │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      On-Chain Contracts                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │ERC-8004 │  │Market   │  │x402     │  │Billing  │           │
│  │Identity │  │Contract │  │Facilitator│ │Contract │           │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 技术栈

- Solidity + Hardhat
- x402 Protocol
- ERC-8004
- Base / Solana
- MCP Protocol

---

## 黑客松赛道

Agentic Commerce / Payments

## License

MIT
