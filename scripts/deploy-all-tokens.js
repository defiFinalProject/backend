const { ethers } = require("hardhat");

async function main() {
  const initialSupply = ethers.parseEther("1000000"); // 初始供应：100万个代币

  // 获取本地测试账户
  const signers = await ethers.getSigners();

  // ✅ 打印所有测试账户地址（用于在 MetaMask 中手动切换）
  console.log("📢 所有测试账户地址：");
  signers.forEach((s, i) => console.log(`signer[${i}]: ${s.address}`));

  const recipients = signers.slice(1); // 第一个是部署者，我们给其余的账户发币
  const sendAmount = ethers.parseEther("100"); // 每人 100 个代币

  // 1. 部署 TokenA
  const TokenA = await ethers.getContractFactory("TokenA");
  const tokenA = await TokenA.deploy(initialSupply);
  await tokenA.waitForDeployment();
  console.log(`✅ TokenA 部署成功，地址: ${tokenA.target}`);

  // 2. 部署 TokenB
  const TokenB = await ethers.getContractFactory("TokenB");
  const tokenB = await TokenB.deploy(initialSupply);
  await tokenB.waitForDeployment();
  console.log(`✅ TokenB 部署成功，地址: ${tokenB.target}`);

  // 3. 部署 TokenC
  const TokenC = await ethers.getContractFactory("TokenC");
  const tokenC = await TokenC.deploy(initialSupply);
  await tokenC.waitForDeployment();
  console.log(`✅ TokenC 部署成功，地址: ${tokenC.target}`);

  // 4. 分发 token 给所有账户（除部署者）
  for (const recipient of recipients) {
    await tokenA.transfer(recipient.address, sendAmount);
    await tokenB.transfer(recipient.address, sendAmount);
    await tokenC.transfer(recipient.address, sendAmount);
    console.log(`🎁 已发送 100 TokenA/B/C 给 ${recipient.address}`);
  }

  // ✅ ✅ ✅ 手动给你当前使用的 MetaMask 地址发 100 个 TokenA/B/C
  const myMetaMaskAddress = "0xdD2FD4581271e230360230F9337D5c0430Bf44C0"; // 👈 你导入的账户
  await tokenA.transfer(myMetaMaskAddress, sendAmount);
  await tokenB.transfer(myMetaMaskAddress, sendAmount);
  await tokenC.transfer(myMetaMaskAddress, sendAmount);
  console.log(`🎁 已额外发送 100 TokenA/B/C 给你的 MetaMask 地址：${myMetaMaskAddress}`);

  console.log("🎉 所有代币分发完成！");
}

main().catch((error) => {
  console.error("❌ 部署失败:", error);
  process.exitCode = 1;
});
