const Government = artifacts.require("DreamGovernment");
const Token = artifacts.require("DreamToken");
const TaxPool = artifacts.require("TaxPool");

const initialTokenSupply = 1000000000000000000000;

module.exports = async (deployer) => {
  const govContract = await deployer.deploy(Government);
  const tokenContract = await deployer.deploy(Token, initialTokenSupply, govContract.address);
  const taxPoolContract = await deployer.deploy(TaxPool, govContract.address, tokenContract.address);
};
