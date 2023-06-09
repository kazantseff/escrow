const { version } = require("chai");

require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-deploy");

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const PRIVATE_KEY_DEPLOYER = process.env.PRIVATE_KEY_DEPLOYER;
const PRIVATE_KEY1 = process.env.PRIVATE_KEY1;
const PRIVATE_KEY2 = process.env.PRIVATE_KEY2;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: [PRIVATE_KEY_DEPLOYER, PRIVATE_KEY1, PRIVATE_KEY2],
      chainId: 5,
      saveDeployments: true,
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
    },
  },
  solidity: "0.8.17",
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  gasReporter: {
    enabled: true,
    outputFile: "gas-reporter.txt",
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    noColors: true,
    token: "ETH",
  },
  mocha: {
    timeout: 300000, // 200 seconds max
  },
  solidity: {
    compilers: [
      {
        version: "0.8.17",
      },
      {
        version: "0.4.24",
      },
    ],
  },
};
