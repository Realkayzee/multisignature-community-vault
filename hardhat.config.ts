import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";


const ALCHEMY_GOERLI_URL = process.env.ALCHEMY_GOERLI_API_URL;

const INFURA_ROPSTEN_URL = process.env.INFURA_ROPSTEN_API_URL;

const PRIVATE_KEY = process.env.PRIVATE_KEY;


module.exports = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      url: ALCHEMY_GOERLI_URL,
      accounts: [PRIVATE_KEY]
    },
    ropsten: {
      url: INFURA_ROPSTEN_URL,
      accounts: [PRIVATE_KEY]
    }
  }
}