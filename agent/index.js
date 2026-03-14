const { ethers } = require('ethers');
const OpenAI = require('open');
/**
 * Service Provider Agent
 * 自主服务提供者
 */
class ServiceAgent {
    constructor(config) {
        this.config = config;
        this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
        this.wallet = new ethers.Wallet(config.privateKey, this.provider);
        this.openai = new OpenAI({ apiKey: config.openaiKey });
        
        this.services = new Map();
        this.clients = new Map();
        this.reputation = 0;
        this.totalEarnings = 0;

        this.running = false;
    }

    /**
     * 启动 Agent
     */
    async start() {
        console.log(`🤖 Service Agent starting...`);
        console.log(`   Address: ${this.wallet.address}`);
        this.running = true;

        // 注册到 Hub
        await this.registerWithHub();

        // 发布服务
        await this.publishServices();

        // 开始监听任务
        await this.listenForJobs();

        console.log('✅ Service Agent running');
    }

    /**
     * 注册到 Hub
     */
    async registerWithHub() {
        console.log('📝 Registering with Hub...');
        
        // 调用 Hub 合约
        // await this.hub.registerAgent(...)
    }

    /**
     * 发布服务
     */
    async publishServices() {
        for (const service of this.config.services) {
            console.log(`📢 Publishing service: ${service.name}`);
            
            const serviceId = `svc_${Date.now()}_${Math.random().toString(36).slice(2)}`;
            
            this.services.set(serviceId, {
                ...service,
                id: serviceId,
                active: true,
                completedJobs: 0,
                totalRevenue: 0
            });

            // 发布到 Hub
            // await this.hub.createService(service)
        }
    }

    /**
     * 监听任务
     */
    async listenForJobs() {
        console.log('👀 Listening for jobs...');
        
        // 轮询或订阅事件
        setInterval(async () => {
            if (!this.running) return;
            
            try {
                await this.checkForJobs();
            } catch (error) {
                console.error(`Error checking jobs: ${error.message}`);
            }
        }, 5000);
    }

    /**
     * 检查任务
     */
    async checkForJobs() {
        // 查询新任务
        // const jobs = await this.hub.getPendingJobs(this.wallet.address);
        
        // for (const job of jobs) {
        //     await this.processJob(job);
        // }
    }

    /**
     * 处理任务
     */
    async processJob(job) {
        console.log(`\n📋 Processing job: ${job.id}`);
        
        // 1. 确认服务
        const service = this.services.get(job.serviceId);
        if (!service) {
            throw new Error('Service not found');
        }

        // 2. AI 执行服务
        const result = await this.executeService(service, job);

        // 3. 提交结果
        await this.submitResult(job.id, result);

        // 4. 更新统计
        service.completedJobs++;
        service.totalRevenue += job.amount;
        this.totalEarnings += job.amount;
        this.reputation += 1;

        console.log(`✅ Job completed: ${job.id}`);
    }

    /**
     * 执行服务
     */
    async executeService(service, job) {
        const prompt = `
You are a service provider. Execute the following service:

Service: ${service.name}
Description: ${service.description}
Client Request: ${JSON.stringify(job.request, null, 2)}

Provide the result as JSON:
{
    "success": boolean,
    "output": any,
    "message": "explanation"
}
`;

        const response = await this.openai.chat.completions.create({
            model: "gpt-4",
            messages: [
                {
                    role: "system",
                    content: `You are a professional service provider. Execute the service accurately and efficiently.`
                },
                {
                    role: "user",
                    content: prompt
                }
            ],
            temperature: 0.3
        });

        return JSON.parse(response.choices[0].message.content);
    }

    /**
     * 提交结果
     */
    async submitResult(jobId, result) {
        console.log(`📤 Submitting result for job: ${jobId}`);
        
        // 调用 Hub 合约
        // await this.hub.completeJob(jobId, result)
    }

    /**
     * 停止 Agent
     */
    stop() {
        console.log('🛑 Service Agent stopping...');
        this.running = false;
    }

    /**
     * 获取统计
     */
    getStats() {
        return {
            address: this.wallet.address,
            services: this.services.size,
            totalEarnings: this.totalEarnings,
            reputation: this.reputation
        };
    }
}

/**
 * Service Consumer Agent
 * 服务消费代理
 */
class ServiceConsumerAgent {
    constructor(config) {
        this.config = config;
        this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
        this.wallet = new ethers.Wallet(config.privateKey, this.provider);
        this.openai = new OpenAI({ apiKey: config.openaiKey });
        
        this.running = false;
        this.pendingJobs = new Map();
    }

    /**
     * 启动 Agent
     */
    async start() {
        console.log(`🤖 Service Consumer Agent starting...`);
        console.log(`   Address: ${this.wallet.address}`);
        this.running = true;

        // 注册到 Hub
        await this.registerWithHub();

        console.log('✅ Service Consumer Agent running');
    }

    /**
     * 发现服务
     */
    async discoverServices(criteria) {
        console.log('🔍 Discovering services...');
        
        // 查询 Hub
        // const services = await this.hub.getActiveServices();
        
        // AI 推荐
        const recommendations = await this.aiRecommend(services, criteria);
        
        return recommendations;
    }

    /**
     * AI 推荐
     */
    async aiRecommend(services, criteria) {
        const prompt = `
You are a service discovery agent. Recommend the best service for the given criteria.

Available Services:
${JSON.stringify(services, null, 2)}

Criteria:
${JSON.stringify(criteria, null, 2)}

Recommend the top 3 services as JSON:
[
    {
        "serviceId": "id",
        "score": 0-100,
        "reason": "explanation"
    }
]
`;

        const response = await this.openai.chat.completions.create({
            model: "gpt-4",
            messages: [
                {
                    role: "system",
                    content: "You are an AI service discovery agent. Find the best services for the user."
                },
                {
                    role: "user",
                    content: prompt
                }
            ],
            temperature: 0.5
        });

        return JSON.parse(response.choices[0].message.content);
    }

    /**
     * 购买服务
     */
    async purchaseService(serviceId, request) {
        console.log(`💳 Purchasing service: ${serviceId}`);
        
        // 创建 x402 支付
        const gateway = new X402PaymentGateway(this.config);
        const payment = await gateway.createPaymentRequest({
            amount: 10, // 示例
            recipient: 'service_provider_address',
            memo: `Payment for service: ${serviceId}`,
            expiresIn: 3600
        });

        // 购买
        // const job = await this.hub.purchaseService(serviceId, payment, request);
        
        // 跟踪任务
        // this.pendingJobs.set(job.id, job);
        
        // return job;
    }

    /**
     * 等待结果
     */
    async waitForResult(jobId, timeout = 300000) {
        console.log(`⏳ Waiting for result: ${jobId}`);
        
        const startTime = Date.now();
        
        while (Date.now() - startTime < timeout) {
            // 检查状态
            // const job = await this.hub.getJob(jobId);
            
            // if (job.status === 'completed') {
            //     return job.result;
            // }
            
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        throw new Error('Job timed out');
    }

    /**
     * 停止 Agent
     */
    stop() {
        console.log('🛑 Service Consumer Agent stopping...');
        this.running = false;
    }
}

// 启动脚本
async function main() {
    const serviceAgent = new ServiceAgent({
        rpcUrl: process.env.RPC_URL,
        privateKey: process.env.PRIVATE_KEY,
        openaiKey: process.env.OPENAI_KEY,
        services: [
            {
                name: 'Data Analysis',
                description: 'Analyze datasets and generate insights',
                price: 10, // USDC
                duration: 3600 // 1 hour
            },
            {
                name: 'Content Generation',
                description: 'Generate high-quality content based on requirements',
                price: 20,
                duration: 1800
            }
        ]
    });

    await serviceAgent.start();
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = { ServiceAgent, ServiceConsumerAgent };
