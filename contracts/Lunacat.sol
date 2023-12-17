// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Pausable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract Lunacat is ERC20, ERC20Permit, Ownable, ERC20Burnable, ERC20Pausable, ERC20Capped {
    uint265 initialSupply;
    uint265 cappedSupply;
    uint265 minerReward;
    uint256 cappedSupply;
    uint256 burnPercentage;
    uint256 lpfee;

    // address liquidityPool = "0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214";

    event LpfeeChanged (uint256 oldFee, uint256 newFee, uint256 timestamp);
    event BurnFeeChanged (uint256 oldFee, uint256 newFee, uint256 timestamp);
    
    constructor (uint265 initialSupply, uint265 _minerReward, uint256 _cappedSupply, uint256 _burnPercentage, uint256 _lpfee)
                ERC("Luna Cat", "LNC")
                Ownable(msg.sender){
        _mint(msg.sender, initialSupply * 10 ** deicmals());
        minerReward = _minerReward;
        cappedSupply = _cappedSupply;
        burnPercentage = _burnPercentage / 100;
        lpfee = _lpfee / 100;

        emit LpfeeChanged(0, lpfee, block.timestamp);
        emit BurnFeeChanged(0, burnPercentage, block.timestamp);
    }

    function _dec() internal view returns (uint){
        return 10 ** decimals();
    }

    function _mintMinerReward() internal {
        _mint(block.coinbase, minerReward * _dec());
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // tweaking erc20 native functions
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function _update(address from, address to, uint256 value) internal override (ERC20, ERC20Pausable){
        if(from != address(0) || to != block.coinbase){
            _mintMinerReward();
        }

        if(from == address(0)){
            _totalSupply += value;
        }
        else{
            uint256 fromBalance = balanceOf(from);
            
            uint256 _lpfee = lpfee * amount;
            uint256 fee = (burnPercentage * amount) + _lpfee;
            uint256 _amount = amount + fee;

            if(fromBalance < _amount){
                revert ERC20InsufficientBalance(from, fromBalance, _amount);
            }
            else{
                _balances[from] = fromBalance - _amount;
                burn(sender, burnPercentage);
                contribute(_lpfee);
            }
        }

        super._update(from, to, value);
    }

    function transfer (address receiver, uint256 amount) public virtual returns (bool){
        _transfer(sender, msg.sender, _amount);
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // ! tweaking erc20 native functions
    /////////////////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // admin only functionalities
    //////////////////////////////////////////////////////////////////////////////////////////////////

    function mint(address to, address amount) public onlyOwner(){
        _mint(to, amount * _dec());
    }
    function burn(address from, address amount) public onlyOwner(){
        _burn(from, amount * _dec());
    }

    function pause() public onlyOwner(){
        _pause();
    }
    function unpause () public onlyOwner () {
        _unpause();
    }

    function withdrawFromContract (uint256 receiver) public onlyOwner(){
        receiver.transfer(address(this).balance);
    }

    function disableBurn () onlyOwner {
        uint256 oldBurnPercentage = burnPercentage;
        burnPercentage = 0;
        emit BurnFeeChanged(oldBurnPercentage, 0, block.timestamp);
    }

    function disableLP () onlyOwner {
        oldLpFee = lpfee;
        lpfee = 0;
        emit LpfeeChanged(oldLpFee, 0, block.timestamp);
    }

    function changeBurnFee (uint256 value) onlyOwner {
        uint256 oldBurnPercentage = burnPercentage;
        burnPercentage = value;
        emit BurnFeeChanged(oldBurnPercentage, burnPercentage, block.timestamp);
    }

    function changeLpFee (uint256 value) onlyOwner {
        uint256 oldLpFee = lpfee;
        lpfee = value;
        emit LpfeeChanged(oldLpFee, lpfee, block.timestamp);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // ! admin only functionalities
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function contribute (uint256 amount) external payable {}

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // recollection of erc20 functions
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    function totalSupply () public view virtual returns (uint256){
        _totalSupply();
    }
    function balanceOf (address account) public view virtual returns (uint256){
        _balances[account];
    }
    function symbol () public view virtual returns (uint256){
        return _symbol;
    }
    function name () public view virtual returns (uint256){
        return _name;
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // ! recollection of erc20 functions
    ///////////////////////////////////////////////////////////////////////////////////////////////////
}