//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract RelayerRegistry is Ownable {
  using SafeMath for uint256;

  IERC20 public immutable TORN;
  mapping(address => Relayer) public relayers;
  uint256 public txFee;

  struct Relayer {
    uint256 balance;
  }

  constructor(IERC20 _torn) {
    TORN = _torn;
  }

  function stake(uint256 _amount) public {
    TORN.transferFrom(msg.sender, address(this), _amount);
    Relayer memory relayer = relayers[msg.sender];
    relayer.balance = relayer.balance.add(_amount);
  }

  function transaction() public {
    Relayer storage relayer = relayers[msg.sender];
    relayer.balance = relayer.balance.sub(txFee);
  }

  function setTxFee(uint256 _txFee) public onlyOwner {
    txFee = _txFee;
  }

  function kick(address _relayer, bool confiscateStake) public onlyOwner {
    Relayer storage relayer = relayers[_relayer];
    if (confiscateStake) {
      TORN.transfer(msg.sender, relayer.balance);
    } else {
      TORN.transfer(_relayer, relayer.balance);
    }
    relayer.balance = 0;
  }
}
