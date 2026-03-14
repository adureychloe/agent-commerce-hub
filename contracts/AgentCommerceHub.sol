// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AgentCommerceHub
 * @dev AI Agent 商业中心
 */
contract AgentCommerceHub is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    // Agent 身份
    struct AgentIdentity {
        address wallet;
        string name;
        string metadata; // IPFS hash
        uint256 reputation;
        uint256 totalEarnings;
        uint256 completedJobs;
        bool verified;
        uint256 registeredAt;
    }

    // 服务定义
    struct Service {
        uint256 id;
        address provider;
        string name;
        string description;
        uint256 price; // in USDC (6 decimals)
        address paymentToken;
        uint256 duration; // seconds
        uint256 completedJobs;
        uint256 totalRevenue;
        bool active;
        uint256 createdAt;
    }

    // 任务/订单
    struct Job {
        uint256 id;
        uint256 serviceId;
        address client;
        address provider;
        uint256 amount;
        address paymentToken;
        JobStatus status;
        uint256 createdAt;
        uint256 completedAt;
        uint256 rating;
    }

    enum JobStatus {
        PENDING,
        IN_PROGRESS,
        COMPLETED,
        DISPUTED,
        CANCELLED
    }

    // x402 支付记录
    struct PaymentRecord {
        bytes32 paymentId;
        uint256 jobId;
        address payer;
        address payee;
        uint256 amount;
        address token;
        uint256 timestamp;
        bool settled;
    }

    // 状态变量
    mapping(address => AgentIdentity) public agents;
    mapping(uint256 => Service) public services;
    mapping(uint256 => Job) public jobs;
    mapping(bytes32 => PaymentRecord) public payments;

    uint256 public serviceCounter;
    uint256 public jobCounter;
    uint256 public platformFee = 250; // 2.5%

    // 事件
    event AgentRegistered(address indexed wallet, string name);
    event AgentVerified(address indexed wallet);
    event ServiceCreated(uint256 indexed id, address provider, string name, uint256 price);
    event JobCreated(uint256 indexed id, uint256 serviceId, address client);
    event JobCompleted(uint256 indexed id, address provider);
    event PaymentSettled(bytes32 indexed paymentId, uint256 jobId, uint256 amount);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(AGENT_ROLE, admin);
    }

    /**
     * @dev 注册 Agent
     */
    function registerAgent(
        string calldata _name,
        string calldata _metadata
    ) external {
        require(agents[msg.sender].registeredAt == 0, "Already registered");
        
        agents[msg.sender] = AgentIdentity({
            wallet: msg.sender,
            name: _name,
            metadata: _metadata,
            reputation: 0,
            totalEarnings: 0,
            completedJobs: 0,
            verified: false,
            registeredAt: block.timestamp
        });

        _grantRole(AGENT_ROLE, msg.sender);
        emit AgentRegistered(msg.sender, _name);
    }

    /**
     * @dev 验证 Agent（管理员）
     */
    function verifyAgent(address _agent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(agents[_agent].registeredAt > 0, "Agent not registered");
        agents[_agent].verified = true;
        emit AgentVerified(_agent);
    }

    /**
     * @dev 创建服务
     */
    function createService(
        string calldata _name,
        string calldata _description,
        uint256 _price,
        address _paymentToken,
        uint256 _duration
    ) external returns (uint256) {
        require(agents[msg.sender].verified, "Agent not verified");
        
        serviceCounter++;
        uint256 serviceId = serviceCounter;
        
        services[serviceId] = Service({
            id: serviceId,
            provider: msg.sender,
            name: _name,
            description: _description,
            price: _price,
            paymentToken: _paymentToken,
            duration: _duration,
            completedJobs: 0,
            totalRevenue: 0,
            active: true,
            createdAt: block.timestamp
        });

        emit ServiceCreated(serviceId, msg.sender, _name, _price);
        return serviceId;
    }

    /**
     * @dev 购买服务（创建任务）
     */
    function purchaseService(
        uint256 _serviceId,
        bytes calldata /* _x402Payload */
    ) external payable returns (uint256) {
        Service storage service = services[_serviceId];
        require(service.active, "Service not active");
        
        // x402 支付验证
        // 实际实现需要验证 x402 payload
        
        jobCounter++;
        uint256 jobId = jobCounter;
        
        jobs[jobId] = Job({
            id: jobId,
            serviceId: _serviceId,
            client: msg.sender,
            provider: service.provider,
            amount: service.price,
            paymentToken: service.paymentToken,
            status: JobStatus.PENDING,
            createdAt: block.timestamp,
            completedAt: 0,
            rating: 0
        });

        emit JobCreated(jobId, _serviceId, msg.sender);
        return jobId;
    }

    /**
     * @dev 完成任务
     */
    function completeJob(uint256 _jobId, uint256 _rating) external {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.IN_PROGRESS || job.status == JobStatus.PENDING, "Invalid status");
        require(job.provider == msg.sender, "Not provider");
        
        job.status = JobStatus.COMPLETED;
        job.completedAt = block.timestamp;
        job.rating = _rating;

        // 转移支付
        _settlePayment(_jobId);

        // 更新统计
        Service storage service = services[job.serviceId];
        service.completedJobs++;
        agents[job.provider].completedJobs++;

        emit JobCompleted(_jobId, msg.sender);
    }

    /**
     * @dev 结算支付
     */
    function _settlePayment(uint256 _jobId) internal {
        Job storage job = jobs[_jobId];
        
        uint256 platformShare = (job.amount * platformFee) / 10000;
        uint256 providerShare = job.amount - platformShare;

        // 转给服务提供者
        IERC20(job.paymentToken).safeTransfer(job.provider, providerShare);
        
        // 转给平台
        IERC20(job.paymentToken).safeTransfer(address(this), platformShare);

        // 更新收益
        agents[job.provider].totalEarnings += providerShare;
        services[job.serviceId].totalRevenue += providerShare;

        bytes32 paymentId = keccak256(abi.encodePacked(_jobId, block.timestamp));
        payments[paymentId] = PaymentRecord({
            paymentId: paymentId,
            jobId: _jobId,
            payer: job.client,
            payee: job.provider,
            amount: providerShare,
            token: job.paymentToken,
            timestamp: block.timestamp,
            settled: true
        });

        emit PaymentSettled(paymentId, _jobId, providerShare);
    }

    /**
     * @dev 获取 Agent 信息
     */
    function getAgent(address _wallet) external view returns (AgentIdentity memory) {
        return agents[_wallet];
    }

    /**
     * @dev 获取服务信息
     */
    function getService(uint256 _serviceId) external view returns (Service memory) {
        return services[_serviceId];
    }

    /**
     * @dev 获取任务信息
     */
    function getJob(uint256 _jobId) external view returns (Job memory) {
        return jobs[_jobId];
    }

    /**
     * @dev 获取活跃服务
     */
    function getActiveServices(uint256 _limit) external view returns (Service[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= serviceCounter && count < _limit; i++) {
            if (services[i].active) {
                count++;
            }
        }
        
        Service[] memory result = new Service[](count);
        count = 0;
        for (uint256 i = 1; i <= serviceCounter && count < _limit; i++) {
            if (services[i].active) {
                result[count] = services[i];
                count++;
            }
        }
        
        return result;
    }

    // 管理函数
    function setPlatformFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_fee <= 1000, "Fee too high"); // max 10%
        platformFee = _fee;
    }

    function deactivateService(uint256 _serviceId) external {
        require(services[_serviceId].provider == msg.sender, "Not provider");
        services[_serviceId].active = false;
    }
}
