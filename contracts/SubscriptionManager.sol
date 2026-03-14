// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SubscriptionManager
 * @dev 订阅管理系统 - Phase 2
 */
contract SubscriptionManager is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");

    // 订阅计划
    struct Plan {
        uint256 id;
        address merchant;
        string name;
        uint256 price;
        address paymentToken;
        uint256 interval;      // 秒
        uint256 trialPeriod;   // 试用期（秒）
        bool active;
        uint256 subscriberCount;
    }

    // 订阅
    struct Subscription {
        uint256 id;
        uint256 planId;
        address subscriber;
        uint256 startTime;
        uint256 nextBilling;
        uint256 endTime;
        SubscriptionStatus status;
        uint256 totalPaid;
    }

    enum SubscriptionStatus {
        NONE,
        ACTIVE,
        PAUSED,
        CANCELLED,
        EXPIRED
    }

    // 状态变量
    mapping(uint256 => Plan) public plans;
    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => uint256[]) public userSubscriptions;
    mapping(address => uint256[]) public merchantPlans;

    uint256 public planCounter;
    uint256 public subscriptionCounter;

    // 事件
    event PlanCreated(uint256 indexed planId, address merchant, string name, uint256 price);
    event PlanDeactivated(uint256 indexed planId);
    event SubscriptionCreated(uint256 indexed subscriptionId, uint256 planId, address subscriber);
    event SubscriptionRenewed(uint256 indexed subscriptionId, uint256 nextBilling);
    event SubscriptionCancelled(uint256 indexed subscriptionId);
    event SubscriptionPaused(uint256 indexed subscriptionId);
    event SubscriptionResumed(uint256 indexed subscriptionId);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MERCHANT_ROLE, admin);
    }

    /**
     * @dev 创建订阅计划
     */
    function createPlan(
        string calldata _name,
        uint256 _price,
        address _paymentToken,
        uint256 _interval,
        uint256 _trialPeriod
    ) external returns (uint256) {
        planCounter++;
        uint256 planId = planCounter;

        plans[planId] = Plan({
            id: planId,
            merchant: msg.sender,
            name: _name,
            price: _price,
            paymentToken: _paymentToken,
            interval: _interval,
            trialPeriod: _trialPeriod,
            active: true,
            subscriberCount: 0
        });

        merchantPlans[msg.sender].push(planId);

        emit PlanCreated(planId, msg.sender, _name, _price);

        return planId;
    }

    /**
     * @dev 订阅计划
     */
    function subscribe(uint256 _planId) external returns (uint256) {
        Plan storage plan = plans[_planId];
        require(plan.active, "Plan not active");

        // 扣款
        IERC20(plan.paymentToken).safeTransferFrom(msg.sender, plan.merchant, plan.price);

        subscriptionCounter++;
        uint256 subscriptionId = subscriptionCounter;

        uint256 startTime = block.timestamp;
        uint256 nextBilling = startTime + plan.trialPeriod + plan.interval;

        subscriptions[subscriptionId] = Subscription({
            id: subscriptionId,
            planId: _planId,
            subscriber: msg.sender,
            startTime: startTime,
            nextBilling: nextBilling,
            endTime: 0,
            status: SubscriptionStatus.ACTIVE,
            totalPaid: plan.price
        });

        userSubscriptions[msg.sender].push(subscriptionId);
        plan.subscriberCount++;

        emit SubscriptionCreated(subscriptionId, _planId, msg.sender);

        return subscriptionId;
    }

    /**
     * @dev 续费
     */
    function renew(uint256 _subscriptionId) external {
        Subscription storage sub = subscriptions[_subscriptionId];
        Plan storage plan = plans[sub.planId];

        require(sub.status == SubscriptionStatus.ACTIVE, "Not active");
        require(block.timestamp >= sub.nextBilling, "Not due yet");

        // 扣款
        IERC20(plan.paymentToken).safeTransferFrom(
            sub.subscriber,
            plan.merchant,
            plan.price
        );

        sub.nextBilling += plan.interval;
        sub.totalPaid += plan.price;

        emit SubscriptionRenewed(_subscriptionId, sub.nextBilling);
    }

    /**
     * @dev 取消订阅
     */
    function cancelSubscription(uint256 _subscriptionId) external {
        Subscription storage sub = subscriptions[_subscriptionId];
        require(sub.subscriber == msg.sender, "Not subscriber");
        require(sub.status == SubscriptionStatus.ACTIVE, "Not active");

        sub.status = SubscriptionStatus.CANCELLED;
        sub.endTime = block.timestamp;

        emit SubscriptionCancelled(_subscriptionId);
    }

    /**
     * @dev 暂停订阅
     */
    function pauseSubscription(uint256 _subscriptionId) external {
        Subscription storage sub = subscriptions[_subscriptionId];
        require(sub.subscriber == msg.sender, "Not subscriber");
        require(sub.status == SubscriptionStatus.ACTIVE, "Not active");

        sub.status = SubscriptionStatus.PAUSED;

        emit SubscriptionPaused(_subscriptionId);
    }

    /**
     * @dev 恢复订阅
     */
    function resumeSubscription(uint256 _subscriptionId) external {
        Subscription storage sub = subscriptions[_subscriptionId];
        require(sub.subscriber == msg.sender, "Not subscriber");
        require(sub.status == SubscriptionStatus.PAUSED, "Not paused");

        sub.status = SubscriptionStatus.ACTIVE;

        emit SubscriptionResumed(_subscriptionId);
    }

    /**
     * @dev 停用计划（商家）
     */
    function deactivatePlan(uint256 _planId) external {
        require(plans[_planId].merchant == msg.sender, "Not merchant");
        plans[_planId].active = false;
        emit PlanDeactivated(_planId);
    }

    /**
     * @dev 检查订阅状态
     */
    function checkSubscription(uint256 _subscriptionId) external view returns (
        bool isActive,
        uint256 nextBilling,
        uint256 remainingDays
    ) {
        Subscription storage sub = subscriptions[_subscriptionId];
        
        isActive = sub.status == SubscriptionStatus.ACTIVE && 
                   block.timestamp < sub.nextBilling;
        nextBilling = sub.nextBilling;
        
        if (nextBilling > block.timestamp) {
            remainingDays = (nextBilling - block.timestamp) / 1 days;
        }
    }

    /**
     * @dev 批量续费
     */
    function batchRenew(uint256[] calldata _subscriptionIds) external {
        for (uint256 i = 0; i < _subscriptionIds.length; i++) {
            Subscription storage sub = subscriptions[_subscriptionIds[i]];
            
            if (sub.status == SubscriptionStatus.ACTIVE && 
                block.timestamp >= sub.nextBilling) {
                
                Plan storage plan = plans[sub.planId];
                
                IERC20(plan.paymentToken).safeTransferFrom(
                    sub.subscriber,
                    plan.merchant,
                    plan.price
                );

                sub.nextBilling += plan.interval;
                sub.totalPaid += plan.price;

                emit SubscriptionRenewed(_subscriptionIds[i], sub.nextBilling);
            }
        }
    }

    /**
     * @dev 获取用户订阅
     */
    function getUserSubscriptions(address _user) external view returns (uint256[] memory) {
        return userSubscriptions[_user];
    }

    /**
     * @dev 获取商家计划
     */
    function getMerchantPlans(address _merchant) external view returns (uint256[] memory) {
        return merchantPlans[_merchant];
    }

    /**
     * @dev 获取计划信息
     */
    function getPlan(uint256 _planId) external view returns (Plan memory) {
        return plans[_planId];
    }

    /**
     * @dev 获取订阅信息
     */
    function getSubscription(uint256 _subscriptionId) external view returns (Subscription memory) {
        return subscriptions[_subscriptionId];
    }
}
