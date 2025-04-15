const { ethers } = require("hardhat");

async function main() {
  const TokenC = await ethers.getContractFactory("TokenC");
  const initialSupply = ethers.utils.parseEther("1000000"); // 初始供应 100万 TKA

  const tokenC = await TokenC.deploy(initialSupply);
  await tokenC.deployed();

    console.log(`TokenC deployed to: ${tokenC.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

