// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Dream token for Dream Government
/// @author Lars Raschke
/// @notice This ERC20 token is collecting fees on simple transfers related to voted government laws.
/// The fees are send to the tax pool.
contract DreamToken is ERC20, Ownable {
    using SafeMath for uint256;

    address public governmentAddress; // government contract address
    address public taxPoolAddress; // tax pool address
    uint8 public taxRate; // current tax rate for transfers

    // modifier to restrict functions access only for government
    modifier onlyGovernment() {
        require(
            msg.sender == governmentAddress,
            "Only government can call this function."
        );
        _;
    }

    /// @notice Minting initial supply to senders address
    /// @param initialSupply The number of initial supplied tokens
    /// @param _govAddress The address of government contract
    constructor(uint256 initialSupply, address _govAddress)
        ERC20("DreamToken", "DRT")
    {
        governmentAddress = _govAddress;
        _mint(msg.sender, initialSupply);
    }

    /// @notice Transfering tokens from sender to receiver and collecting taxes
    /// @param amount The total number of tokens to be transfered
    /// @param recipient The address of the token receiver
    /// @return bool for successful transfer
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        (uint256 tax, uint256 _amount) = calculateSendingAmounts(amount);
        _transfer(msg.sender, recipient, _amount);
        _transfer(msg.sender, taxPoolAddress, tax);
        return true;
    }

    /// @notice Calculating tax and remaining send amount for transfers
    /// @param amount The total number of tokens to be transfered
    /// @return tax amount and remaining sending amount
    function calculateSendingAmounts(uint256 amount)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 tax = amount.mul(taxRate).div(10000);
        uint256 amountAfterTax = amount.sub(tax);

        return (tax, amountAfterTax);
    }

    /// @notice Setting the current tax fee by government.
    /// @param _taxRate The tax rate applied to every transfer.
    function setTaxRate(uint8 _taxRate) external onlyGovernment {
        taxRate = _taxRate;
    }

    /// @notice Setting the tax pool address by government.
    /// @param _taxPoolAddress The address of the tax pool.
    function setTaxPoolAddress(address _taxPoolAddress) external onlyOwner {
        taxPoolAddress = _taxPoolAddress;
    }
}
