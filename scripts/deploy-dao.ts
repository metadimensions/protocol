import { ethers } from "hardhat";

async function main() {
  console.log('Deploying protocol/Sector3DAO.sol')
  
  console.log('process.env.DEPLOYER_PRIVATE_KEY exists:', process.env.DEPLOYER_PRIVATE_KEY != undefined)
  console.log('process.env.ETHERSCAN_API_KEY exists:', process.env.ETHERSCAN_API_KEY != undefined)
  
  const Sector3DAO = await ethers.getContractFactory("Sector3DAO");
  const sector3DAO = await Sector3DAO.deploy("Sector#3 DAO", "Enable autonomous DAO contributions", "0x610210AA5D51bf26CBce146A5992D2FEeBc27dB1");

  await sector3DAO.deployed();

  console.log(`Sector3DAO deployed to ${sector3DAO.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
