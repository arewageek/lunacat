require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    zircuit: {
      url: `https://zircuit1.p2pify.com`,
      accounts: [process.env.ZIRCUIT_PRIVATE_KEY]
    }
  }
};
