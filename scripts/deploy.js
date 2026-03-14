const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying Agent Commerce Hub...\n");

  // 1. 部署 AgentCommerceHub
  console.log("📦 Deploying AgentCommerceHub...");
  const AgentCommerceHub = await hre.ethers.getContractFactory("AgentCommerceHub");
  const hub = await AgentCommerceHub.deploy(
    (await hre.ethers.getSigners())[0].address
  );
  await hub.waitForDeployment();
  const hubAddress = await hub.getAddress();
  console.log(`   ✅ AgentCommerceHub: ${hubAddress}\n`);

  // 2. 部署 A2AMarketplace
  console.log("📦 Deploying A2AMarketplace...");
  const A2AMarketplace = await hre.ethers.getContractFactory("A2AMarketplace");
  const a2a = await A2AMarketplace.deploy(
    (await hre.ethers.getSigners())[0].address
  );
  await a2a.waitForDeployment();
  const a2aAddress = await a2a.getAddress();
  console.log(`   ✅ A2AMarketplace: ${a2aAddress}\n`);

  // 3. 测试注册 Agent
  console.log("🧪 Testing Agent Registration...");
  const [deployer] = await hre.ethers.getSigners();
  
  const registerTx = await hub.registerAgent(
    "Test Agent",
    "ipfs://QmTest123"
  );
  await registerTx.wait();
  console.log("   ✅ Agent registered\n");

  // 4. 获取 Agent 信息
  const agentInfo = await hub.getAgent(deployer.address);
  console.log("📋 Agent Info:");
  console.log(`   Name: ${agentInfo.name}`);
  console.log(`   Wallet: ${agentInfo.wallet}`);
  console.log(`   Reputation: ${agentInfo.reputation}`);
  console.log(`   Verified: ${agentInfo.verified}\n`);

  // 5. 验证 Agent
  console.log("🔐 Verifying Agent...");
  const verifyTx = await hub.verifyAgent(deployer.address);
  await verifyTx.wait();
  const verifiedAgent = await hub.getAgent(deployer.address);
  console.log(`   ✅ Agent verified: ${verifiedAgent.verified}\n`);

  // 6. 创建服务
  console.log("🛒 Creating Service...");
  const USDC_ADDRESS = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"; // Base USDC
  const createServiceTx = await hub.createService(
    "Data Analysis",
    "AI-powered data analysis service",
    hre.ethers.parseUnits("10", 6), // 10 USDC
    USDC_ADDRESS,
    3600 // 1 hour
  );
  await createServiceTx.wait();
  const serviceInfo = await hub.getService(1);
  console.log("   ✅ Service created");
  console.log(`   Name: ${serviceInfo.name}`);
  console.log(`   Price: ${hre.ethers.formatUnits(serviceInfo.price, 6)} USDC`);
  console.log(`   Duration: ${serviceInfo.duration} seconds\n`);

  // 7. 测试 A2A 消息
  console.log("💬 Testing A2A Messaging...");
  const messageTx = await a2a.sendMessage(
    deployer.address,
    hre.ethers.toUtf8Bytes("Hello from Agent!")
  );
  await messageTx.wait();
  console.log("   ✅ A2A message sent\n");

  // 8. 测试谈判
  console.log("🤝 Testing Negotiation...");
  const negotiateTx = await a2a.startNegotiation(
    deployer.address,
    1, // serviceId
    hre.ethers.parseUnits("8", 6) // 8 USDC
  );
  await negotiateTx.wait();
  console.log("   ✅ Negotiation started\n");

  // 9. 输出部署摘要
  console.log("═".repeat(50));
  console.log("📋 Deployment Summary");
  console.log("═".repeat(50));
  console.log(`Network: ${hre.network.name}`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`AgentCommerceHub: ${hubAddress}`);
  console.log(`A2AMarketplace: ${a2aAddress}`);
  console.log("═".repeat(50));
  console.log("\n✅ All tests passed!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
