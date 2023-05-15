const { ethers, network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;
  const chainId = network.config.chainId;

  let escrow;
  let addresses = [];
  const signers = await ethers.getSigners();

  for (let i = 0; i < 3; i++) {
    let address = await signers[i].getAddress();
    addresses.push(address);
  }

  let interval = "300"; // 5 mintes;
  let fee = ethers.utils.parseEther("1"); // 1% fee

  let args = [addresses[1], addresses[2], interval, fee];

  escrow = await deploy("Escrow", {
    from: deployer,
    args: args,
    log: true,
    value: ethers.utils.parseEther("0.01"),
  });
};

module.exports.tags = ["all", "escrow"];
