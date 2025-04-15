const { ethers } = require("hardhat");

async function main() {
  // ✅ 替换为你已部署的 TokenA 和 TokenB 地址
  const tokenAAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const tokenBAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

  // ✅ 获取合约工厂并部署 ConstantSumPool
  const ConstantSumPool = await ethers.getContractFactory("ConstantSumPool");
  const pool = await ConstantSumPool.deploy(tokenAAddress, tokenBAddress);

  await pool.waitForDeployment();

  console.log("✅ ConstantSumPool 合约部署成功！");
  console.log("📍 合约地址:", pool.target);
}

main().catch((error) => {
  console.error("❌ 部署失败:", error);
  process.exitCode = 1;
});
