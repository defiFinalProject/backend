const { ethers } = require("hardhat");

async function main() {
  const TokenA = await ethers.getContractFactory("TokenA");
  const initialSupply = ethers.utils.parseEther("1000000"); // 初始供应 100万 TKA

  const tokenA = await TokenA.deploy(initialSupply);
  await tokenA.deployed();

  console.log(`TokenA deployed to: ${tokenA.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


