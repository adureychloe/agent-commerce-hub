import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useAccount, useConnect, useDisconnect } from 'wagmi';

// Agent Commerce Hub Dashboard
const Dashboard = () => {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  const [stats, setStats] = useState({
    totalAgents: 0,
    totalServices: 0,
    totalJobs: 0,
    totalVolume: '0'
  });

  const [agents, setAgents] = useState([]);
  const [services, setServices] = useState([]);
  const [jobs, setJobs] = useState([]);

  // 合约地址
  const HUB_ADDRESS = '0x2F4E6dA18A90C00a06bE7c56914449D580E69a12';
  const A2A_ADDRESS = '0xCae94409245Dc899E4737643442E3CafAf79b9d1';

  // 加载统计数据
  useEffect(() => {
    if (isConnected) {
      loadStats();
      loadAgents();
      loadServices();
      loadJobs();
    }
  }, [isConnected]);

  const loadStats = async () => {
    // 模拟数据
    setStats({
      totalAgents: 42,
      totalServices: 128,
      totalJobs: 1567,
      totalVolume: '125,420'
    });
  };

  const loadAgents = async () => {
    setAgents([
      {
        address: '0x1234...5678',
        name: 'Data Analyzer',
        reputation: 4.8,
        completedJobs: 156,
        earnings: '12.5 USDC'
      },
      {
        address: '0xabcd...efgh',
        name: 'Content Generator',
        reputation: 4.5,
        completedJobs: 89,
        earnings: '8.3 USDC'
      }
    ]);
  };

  const loadServices = async () => {
    setServices([
      {
        id: 1,
        name: 'Data Analysis',
        provider: '0x1234...5678',
        price: '10 USDC',
        duration: '1 hour',
        completedJobs: 45
      },
      {
        id: 2,
        name: 'Content Writing',
        provider: '0xabcd...efgh',
        price: '5 USDC',
        duration: '30 min',
        completedJobs: 32
      }
    ]);
  };

  const loadJobs = async () => {
    setJobs([
      {
        id: 1,
        service: 'Data Analysis',
        client: '0x9999...1111',
        status: 'completed',
        amount: '10 USDC'
      },
      {
        id: 2,
        service: 'Content Writing',
        client: '0x8888...2222',
        status: 'in_progress',
        amount: '5 USDC'
      }
    ]);
  };

  // 连接钱包
  const handleConnect = async () => {
    if (connectors.length > 0) {
      connect({ connector: connectors[0] });
    }
  };

  // 注册 Agent
  const registerAgent = async () => {
    console.log('Registering agent...');
    // 实际调用合约
  };

  // 创建服务
  const createService = async () => {
    console.log('Creating service...');
    // 实际调用合约
  };

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-white mb-8">
            🏪 Agent Commerce Hub
          </h1>
          <button
            onClick={handleConnect}
            className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg"
          >
            Connect Wallet
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      {/* Header */}
      <header className="bg-gray-800 border-b border-gray-700">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold">🏪 Agent Commerce Hub</h1>
          <div className="flex items-center space-x-4">
            <span className="text-sm text-gray-400">
              {address?.slice(0, 6)}...{address?.slice(-4)}
            </span>
            <button
              onClick={() => disconnect()}
              className="text-sm text-red-400 hover:text-red-300"
            >
              Disconnect
            </button>
          </div>
        </div>
      </header>

      {/* Stats */}
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-gray-800 rounded-lg p-6">
            <p className="text-gray-400 text-sm">Total Agents</p>
            <p className="text-3xl font-bold">{stats.totalAgents}</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-6">
            <p className="text-gray-400 text-sm">Total Services</p>
            <p className="text-3xl font-bold">{stats.totalServices}</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-6">
            <p className="text-gray-400 text-sm">Total Jobs</p>
            <p className="text-3xl font-bold">{stats.totalJobs}</p>
          </div>
          <div className="bg-gray-800 rounded-lg p-6">
            <p className="text-gray-400 text-sm">Total Volume</p>
            <p className="text-3xl font-bold">${stats.totalVolume}</p>
          </div>
        </div>

        {/* Actions */}
        <div className="mt-8 flex space-x-4">
          <button
            onClick={registerAgent}
            className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Register Agent
          </button>
          <button
            onClick={createService}
            className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
          >
            Create Service
          </button>
        </div>

        {/* Agents */}
        <div className="mt-8">
          <h2 className="text-xl font-bold mb-4">🤖 Agents</h2>
          <div className="bg-gray-800 rounded-lg overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-700">
                <tr>
                  <th className="px-4 py-2 text-left">Name</th>
                  <th className="px-4 py-2 text-left">Reputation</th>
                  <th className="px-4 py-2 text-left">Jobs</th>
                  <th className="px-4 py-2 text-left">Earnings</th>
                </tr>
              </thead>
              <tbody>
                {agents.map((agent, i) => (
                  <tr key={i} className="border-t border-gray-700">
                    <td className="px-4 py-2">{agent.name}</td>
                    <td className="px-4 py-2">⭐ {agent.reputation}</td>
                    <td className="px-4 py-2">{agent.completedJobs}</td>
                    <td className="px-4 py-2">{agent.earnings}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Services */}
        <div className="mt-8">
          <h2 className="text-xl font-bold mb-4">🛒 Services</h2>
          <div className="bg-gray-800 rounded-lg overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-700">
                <tr>
                  <th className="px-4 py-2 text-left">Name</th>
                  <th className="px-4 py-2 text-left">Price</th>
                  <th className="px-4 py-2 text-left">Duration</th>
                  <th className="px-4 py-2 text-left">Jobs</th>
                </tr>
              </thead>
              <tbody>
                {services.map((service, i) => (
                  <tr key={i} className="border-t border-gray-700">
                    <td className="px-4 py-2">{service.name}</td>
                    <td className="px-4 py-2">{service.price}</td>
                    <td className="px-4 py-2">{service.duration}</td>
                    <td className="px-4 py-2">{service.completedJobs}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Jobs */}
        <div className="mt-8">
          <h2 className="text-xl font-bold mb-4">📋 Recent Jobs</h2>
          <div className="bg-gray-800 rounded-lg overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-700">
                <tr>
                  <th className="px-4 py-2 text-left">Service</th>
                  <th className="px-4 py-2 text-left">Client</th>
                  <th className="px-4 py-2 text-left">Status</th>
                  <th className="px-4 py-2 text-left">Amount</th>
                </tr>
              </thead>
              <tbody>
                {jobs.map((job, i) => (
                  <tr key={i} className="border-t border-gray-700">
                    <td className="px-4 py-2">{job.service}</td>
                    <td className="px-4 py-2">{job.client}</td>
                    <td className="px-4 py-2">
                      <span className={`px-2 py-1 rounded text-xs ${
                        job.status === 'completed' ? 'bg-green-600' : 'bg-yellow-600'
                      }`}>
                        {job.status}
                      </span>
                    </td>
                    <td className="px-4 py-2">{job.amount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-gray-800 border-t border-gray-700 mt-16">
        <div className="max-w-7xl mx-auto px-4 py-4 text-center text-gray-400">
          <p>Agent Commerce Hub - Built for the Agentic Economy</p>
        </div>
      </footer>
    </div>
  );
};

export default Dashboard;
