const { ethers } = require('ethers');

/**
 * x402 Payment Gateway
 * HTTP 402 支付网关
 */
class X402PaymentGateway {
    constructor(config) {
        this.config = config;
        this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
        this.wallet = new ethers.Wallet(config.privateKey, this.provider);
        this.paymentToken = config.paymentToken;
        this.facilitator = config.facilitator;
    }

    /**
     * 创建 x402 支付请求
     */
    async createPaymentRequest(paymentData) {
        const {
            amount,
            recipient,
            memo,
            expiresIn
        } = paymentData;

        // 生成支付 ID
        const paymentId = this.generatePaymentId();

        // 构建支付 URL
        const paymentUrl = this.buildPaymentUrl({
            paymentId,
            amount,
            recipient,
            memo,
            expiresAt: Math.floor(Date.now() / 1000) + expiresIn
        });

        return {
            paymentId,
            paymentUrl,
            amount,
            recipient,
            expiresAt: Date.now() + expiresIn * 1000
        };
    }

    /**
     * 验证 x402 支付
     */
    async verifyPayment(x402Payload) {
        try {
            // 解析 payload
            const payload = this.parsePayload(x402Payload);
            
            // 验证签名
            const isValid = await this.verifySignature(payload);
            
            if (!isValid) {
                return { valid: false, error: 'Invalid signature' };
            }

            // 验证金额
            const amountValid = await this.verifyAmount(payload);
            
            if (!amountValid) {
                return { valid: false, error: 'Invalid amount' };
            }

            // 验证过期时间
            if (payload.expiresAt < Date.now() / 1000) {
                return { valid: false, error: 'Payment expired' };
            }

            return { valid: true, payload };
        } catch (error) {
            return { valid: false, error: error.message };
        }
    }

    /**
     * 结算支付
     */
    async settlePayment(paymentId, payload) {
        console.log(`💳 Settling payment: ${paymentId}`);

        // 验证支付
        const verification = await this.verifyPayment(payload);
        
        if (!verification.valid) {
            throw new Error(`Payment verification failed: ${verification.error}`);
        }

        // 执行转账
        const tx = await this.executeTransfer(verification.payload);
        
        console.log(`   TX: ${tx.hash}`);
        
        return {
            success: true,
            txHash: tx.hash,
            amount: verification.payload.amount,
            recipient: verification.payload.recipient
        };
    }

    /**
     * 生成支付 ID
     */
    generatePaymentId() {
        return 'x402_' + ethers.hexlify(ethers.randomBytes(16)).slice(2);
    }

    /**
     * 构建支付 URL
     */
    buildPaymentUrl(params) {
        const queryParams = new URLSearchParams({
            id: params.paymentId,
            amount: params.amount.toString(),
            recipient: params.recipient,
            memo: params.memo || '',
            expires: params.expiresAt.toString()
        });

        return `x402://${this.config.network}?${queryParams.toString()}`;
    }

    /**
     * 解析 payload
     */
    parsePayload(x402Payload) {
        if (typeof x402Payload === 'string') {
            return JSON.parse(Buffer.from(x402Payload, 'base64').toString());
        }
        return x402Payload;
    }

    /**
     * 验证签名
     */
    async verifySignature(payload) {
        // 实际实现需要验证 ECDSA 签名
        return true;
    }

    /**
     * 验证金额
     */
    async verifyAmount(payload) {
        // 实际实现需要检查链上余额
        return true;
    }

    /**
     * 执行转账
     */
    async executeTransfer(payload) {
        // 实际实现需要调用 ERC20 transfer
        return { hash: '0x' + '0'.repeat(64) };
    }
}

/**
 * Billing System
 * 账单与结算系统
 */
class BillingSystem {
    constructor(config) {
        this.config = config;
        this.invoices = new Map();
        this.subscriptions = new Map();
    }

    /**
     * 创建发票
     */
    async createInvoice(invoiceData) {
        const {
            clientId,
            items,
            dueDate,
            memo
        } = invoiceData;

        const invoiceId = 'inv_' + Date.now();
        
        // 计算总额
        const total = items.reduce((sum, item) => sum + item.amount, 0);

        const invoice = {
            id: invoiceId,
            clientId,
            items,
            total,
            dueDate,
            memo,
            status: 'pending',
            createdAt: Date.now(),
            paidAt: null,
            transactions: []
        };

        this.invoices.set(invoiceId, invoice);

        return invoice;
    }

    /**
     * 支付发票
     */
    async payInvoice(invoiceId, x402Payload) {
        const invoice = this.invoices.get(invoiceId);
        
        if (!invoice) {
            throw new Error('Invoice not found');
        }

        if (invoice.status === 'paid') {
            throw new Error('Invoice already paid');
        }

        // 验证支付
        const gateway = new X402PaymentGateway(this.config);
        const verification = await gateway.verifyPayment(x402Payload);

        if (!verification.valid) {
            throw new Error(`Payment verification failed: ${verification.error}`);
        }

        // 结算
        const settlement = await gateway.settlePayment(invoiceId, x402Payload);

        // 更新发票
        invoice.status = 'paid';
        invoice.paidAt = Date.now();
        invoice.transactions.push({
            txHash: settlement.txHash,
            amount: settlement.amount,
            timestamp: Date.now()
        });

        return invoice;
    }

    /**
     * 创建订阅
     */
    async createSubscription(subscriptionData) {
        const {
            clientId,
            serviceId,
            price,
            interval, // days
            paymentMethod
        } = subscriptionData;

        const subscriptionId = 'sub_' + Date.now();

        const subscription = {
            id: subscriptionId,
            clientId,
            serviceId,
            price,
            interval,
            paymentMethod,
            status: 'active',
            createdAt: Date.now(),
            nextBilling: Date.now() + interval * 86400000,
            billingHistory: []
        };

        this.subscriptions.set(subscriptionId, subscription);

        return subscription;
    }

    /**
     * 处理订阅账单
     */
    async processSubscriptionBilling() {
        const now = Date.now();
        
        for (const [id, sub] of this.subscriptions) {
            if (sub.status !== 'active') continue;
            
            if (sub.nextBilling <= now) {
                // 生成账单
                await this.billSubscription(sub);
                
                // 更新下次账单日期
                sub.nextBilling = now + sub.interval * 86400000;
            }
        }
    }

    /**
     * 订阅扣款
     */
    async billSubscription(subscription) {
        console.log(`💳 Billing subscription: ${subscription.id}`);
        
        // 创建发票
        const invoice = await this.createInvoice({
            clientId: subscription.clientId,
            items: [{
                description: `Subscription: ${subscription.serviceId}`,
                amount: subscription.price
            }],
            dueDate: Date.now() + 86400000, // 1 day
            memo: 'Subscription billing'
        });

        // 自动扣款（如果设置了自动支付）
        if (subscription.paymentMethod === 'auto') {
            // 通过 x402 自动支付
        }

        subscription.billingHistory.push({
            invoiceId: invoice.id,
            amount: subscription.price,
            timestamp: Date.now()
        });
    }

    /**
     * 获取发票
     */
    getInvoice(invoiceId) {
        return this.invoices.get(invoiceId);
    }

    /**
     * 获取订阅
     */
    getSubscription(subscriptionId) {
        return this.subscriptions.get(subscriptionId);
    }

    /**
     * 取消订阅
     */
    cancelSubscription(subscriptionId) {
        const subscription = this.subscriptions.get(subscriptionId);
        
        if (subscription) {
            subscription.status = 'cancelled';
        }
    }
}

module.exports = { X402PaymentGateway, BillingSystem };
