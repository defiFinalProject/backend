// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 部署合约，并传递正确的参数（代币A, B, C的地址）
  const tokenAAddress = "0xYourTokenAAddress";  // 替换为实际的代币A地址
  const tokenBAddress = "0xYourTokenBAddress";  // 替换为实际的代币B地址
  const tokenCAddress = "0xYourTokenCAddress";  // 替换为实际的代币C地址

  const ConstantMeanPool = await ethers.getContractFactory("ConstantMeanPool");
  const pool = await ConstantMeanPool.deploy(tokenAAddress, tokenBAddress, tokenCAddress);

  console.log("ConstantMeanPool deployed to:", pool.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  