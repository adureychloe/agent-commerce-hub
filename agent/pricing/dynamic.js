const { ethers } = require('ethers');

/**
 * Dynamic Pricing Engine
 * AI 驱动的动态定价引擎 - Phase 2
 */
class DynamicPricingEngine {
    constructor(config) {
        this.config = config;
        this.priceHistory = new Map();
        this.marketData = new Map();
        this.competitorPrices = new Map();
        
        // 定价因素权重
        this.weights = {
            demand: 0.3,
            competition: 0.25,
            time: 0.15,
            reputation: 0.15,
            history: 0.15
        };
    }

    /**
     * 计算最优价格
     */
    async calculateOptimalPrice(service) {
        const basePrice = service.basePrice;
        
        // 获取各因素
        const demandFactor = await this.getDemandFactor(service);
        const competitionFactor = await this.getCompetitionFactor(service);
        const timeFactor = this.getTimeFactor();
        const reputationFactor = this.getReputationFactor(service.provider);
        const historyFactor = this.getHistoryFactor(service.id);

        // 加权计算
        const adjustment = 
            demandFactor * this.weights.demand +
            competitionFactor * this.weights.competition +
            timeFactor * this.weights.time +
            reputationFactor * this.weights.reputation +
            historyFactor * this.weights.history;

        // 计算最终价格
        let price = basePrice * (1 + adjustment);

        // 限制范围
        price = Math.max(this.config.minPrice || basePrice * 0.5, price);
        price = Math.min(this.config.maxPrice || basePrice * 2, price);

        // 记录价格历史
        this.recordPrice(service.id, price);

        return Math.round(price * 1000000); // USDC decimals
    }

    /**
     * 需求因素
     */
    async getDemandFactor(service) {
        // 获取服务请求频率
        const requestRate = await this.getRequestRate(service.id);
        
        // 获取完成率
        const completionRate = await this.getCompletionRate(service.id);
        
        // 计算需求因素
        // 高请求率 + 高完成率 = 高需求
        if (requestRate > 10 && completionRate > 0.8) {
            return 0.2; // +20%
        } else if (requestRate > 5 && completionRate > 0.6) {
            return 0.1; // +10%
        } else if (requestRate < 2) {
            return -0.1; // -10%
        }
        
        return 0;
    }

    /**
     * 竞争因素
     */
    async getCompetitionFactor(service) {
        // 获取同类服务
        const competitors = await this.getCompetitors(service.category);
        
        if (competitors.length === 0) {
            return 0.15; // 无竞争，+15%
        }

        // 计算平均价格
        const avgPrice = competitors.reduce((sum, c) => sum + c.price, 0) / competitors.length;
        
        // 与平均价格比较
        const priceRatio = service.basePrice / avgPrice;
        
        if (priceRatio < 0.8) {
            return 0.1; // 低于市场价，+10%
        } else if (priceRatio > 1.2) {
            return -0.1; // 高于市场价，-10%
        }
        
        return 0;
    }

    /**
     * 时间因素
     */
    getTimeFactor() {
        const hour = new Date().getUTCHours();
        
        // 高峰期（UTC 14-22）
        if (hour >= 14 && hour <= 22) {
            return 0.1; // +10%
        }
        
        // 低谷期（UTC 2-8）
        if (hour >= 2 && hour <= 8) {
            return -0.05; // -5%
        }
        
        return 0;
    }

    /**
     * 信誉因素
     */
    getReputationFactor(provider) {
        const reputation = this.getProviderReputation(provider);
        
        // 高信誉溢价
        if (reputation > 4.5) {
            return 0.15; // +15%
        } else if (reputation > 4.0) {
            return 0.1; // +10%
        } else if (reputation < 3.0) {
            return -0.1; // -10%
        }
        
        return 0;
    }

    /**
     * 历史因素
     */
    getHistoryFactor(serviceId) {
        const history = this.priceHistory.get(serviceId);
        
        if (!history || history.length < 5) {
            return 0;
        }

        // 分析价格趋势
        const recentPrices = history.slice(-5);
        const avgRecent = recentPrices.reduce((a, b) => a + b, 0) / recentPrices.length;
        const trend = (recentPrices[4] - recentPrices[0]) / recentPrices[0];

        // 上涨趋势
        if (trend > 0.1) {
            return 0.05;
        } else if (trend < -0.1) {
            return -0.05;
        }
        
        return 0;
    }

    /**
     * 记录价格
     */
    recordPrice(serviceId, price) {
        if (!this.priceHistory.has(serviceId)) {
            this.priceHistory.set(serviceId, []);
        }
        this.priceHistory.get(serviceId).push({
            price,
            timestamp: Date.now()
        });
    }

    /**
     * 更新市场数据
     */
    updateMarketData(category, data) {
        this.marketData.set(category, {
            ...data,
            timestamp: Date.now()
        });
    }

    /**
     * 更新竞争者价格
     */
    updateCompetitorPrice(serviceId, price) {
        this.competitorPrices.set(serviceId, {
            price,
            timestamp: Date.now()
        });
    }

    // 辅助方法（模拟实现）
    async getRequestRate(serviceId) {
        return Math.random() * 15;
    }

    async getCompletionRate(serviceId) {
        return 0.5 + Math.random() * 0.5;
    }

    async getCompetitors(category) {
        return [];
    }

    getProviderReputation(provider) {
        return 3 + Math.random() * 2;
    }

    /**
     * 获取定价因素详情
     */
    getPricingBreakdown(service) {
        return {
            demandFactor: this.getDemandFactor(service),
            competitionFactor: this.getCompetitionFactor(service),
            timeFactor: this.getTimeFactor(),
            reputationFactor: this.getReputationFactor(service.provider),
            historyFactor: this.getHistoryFactor(service.id),
            weights: this.weights
        };
    }
}

module.exports = { DynamicPricingEngine };
