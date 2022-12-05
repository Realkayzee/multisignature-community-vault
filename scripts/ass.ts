import { ethers } from "hardhat";
const helpers = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
  

  const DataStore = await ethers.getContractFactory("DataStore");
  const dataStore = await DataStore.deploy();

  await dataStore.deployed();

  console.log("Lock with 1 ETH deployed to:", dataStore.address);
  const getslot = await helpers.getStorageAt(dataStore, "15");
  console.log(getslot)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});