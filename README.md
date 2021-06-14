# dreamsystem

This is a short project created with solidity smart contract.

The dream system represents a system with a government, an ERC20 token, a tax pool and a lottery (not implemented yet).
Users of the dream system can stae dream tokens in the government contract to have the right to vote several economic laws on each government cycle. One cycle has a given amount of life time with special periods: 
1. At the start of a cycle, users can stake dream tokens for a short period of time. 
2. At the end of each cycle users can vote for the laws of the next cycle for a short period of time. 
They can vote for a transfer fee applied on every simple token transfer and a lottery propotion of the tax pool. 

The transfer fees are collected by the tax pool. After every government cycle a voted proportion of the tax pool is send to the lottery. The remainig tokens of the tax pool are sent to the government contract. The lottery contract is not implemented yet. It is planned, that a random number is generated by a off-chain oracle and users can guess this number in proportion to their stakes on government contract. 

The users have the following voting options for each lifecycle:
1. tax rate type: 10%, 20% or 30% collected on every simple transfer (collected by tax pool)
2. lottery rate type: 25%, 50% or 75% of the collected taxes are sent to the lottery winnable by stakers.