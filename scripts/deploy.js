const { ethers } = require("hardhat");

async function main() {
  const NFTifyHub = await ethers.getContractFactory("NFTifyHub");
  const nFTifyHub = await NFTifyHub.deploy();

  await nFTifyHub.deployed();

  console.log("NFTifyHub contract deployed to:", nFTifyHub.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
