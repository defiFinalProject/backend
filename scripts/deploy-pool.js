// scripts/deploy-pool.js
const { ethers } = require("hardhat");

async function main() {
  const tokenA = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const tokenB = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const tokenC = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

  const Pool = await ethers.getContractFactory("ConstantMeanPool");
  const pool = await Pool.deploy(tokenA, tokenB, tokenC);
  await pool.waitForDeployment();

  console.log(`✅ ConstantMeanPool 合约部署成功！地址: ${pool.target}`);
}

main().catch((err) => {
  console.error("❌ 部署失败:", err);
  process.exitCode = 1;
});
