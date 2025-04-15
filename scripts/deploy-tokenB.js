const { ethers } = require("hardhat");

async function main() {
  const TokenB = await ethers.getContractFactory("TokenB");
  const initialSupply = ethers.utils.parseEther("1000000"); // 初始供应 100万 TKA

  const tokenB = await TokenB.deploy(initialSupply);
  await tokenB.deployed();

  console.log(`TokenB deployed to: ${tokenB.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

