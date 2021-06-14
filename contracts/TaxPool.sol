// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DreamGovernment.sol";

/// @title Tax pool for Dream Government
/// @author Lars Raschke
/// @notice This pool collects all fees by a simple transfer on dream token.
/// On the end of each government cycle the government sends an amount voted by the
/// stakers to the lottery pool.
contract TaxPool {
    using SafeMath for uint256;
    
    DreamGovernment public government; // government contract 
    IERC20 public dreamToken;          //erc20 dreamtoken contract
    
    // modifier to restrict functions access only for government
    modifier onlyGovernment() {
        require(
            msg.sender == address(government),
            "Only government can call this function."
        );
        _;
    }
    
    /// @notice Setting references for government and dream token contracts
    /// @param _govAddress The address of the government contract
    /// @param _tokenAddress The address of the token contract
    constructor(address _govAddress, address _tokenAddress) {
        government = DreamGovernment(_govAddress);
        dreamToken = IERC20(_tokenAddress);
    }
    
    /// @notice Sending voted proportion of the tax pool to lottery contract
    function collectTaxesForLottery() external onlyGovernment{
        dreamToken.transfer(government.getLotteryAddress(), getLotteryAmount());
    }
    
    /// @notice Get current amount of DreamToken in tax pool 
    /// @return current balance of tax pool
    function getTotalTaxes() public view returns(uint256){
        return dreamToken.balanceOf(address(this));
    }
    
    /// @notice Calculating total amount of lottery with currently voted proportion
    /// @return current lottery amount
    function getLotteryAmount() public view returns(uint256){
        return getTotalTaxes().mul(government.getLotteryRate()).div(10000);
    }
}