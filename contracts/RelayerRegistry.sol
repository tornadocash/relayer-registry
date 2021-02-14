// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "torn-token/contracts/ENS.sol";

contract RelayerRegistry is EnsResolve {
  address public immutable governance;
  IERC20 public immutable torn;
  uint256 public stake;
  mapping(bytes32 => bool) public isRelayer;
  mapping(bytes32 => uint256) public balances;

  event RelayerAdded(bytes32 indexed relayer, uint256 stake);
  event RelayerRemoved(bytes32 indexed relayer, uint256 stake);
  event StakeChanged(uint256 stake);

  constructor(address _governance, IERC20 _torn) public {
    governance = _governance;
    torn = _torn;
  }

  function add(bytes32 _relayer) public {
    require(!isRelayer[_relayer], "The relayer already exists");
    uint256 _stake = stake;
    if (_stake > 0) {
      address addr = resolve(_relayer);
      require(torn.transferFrom(addr, address(this), _stake), "TORN stake transfer failed");
      balances[_relayer] = _stake;
    }
    isRelayer[_relayer] = true;
    emit RelayerAdded(_relayer, _stake);
  }

  function remove(bytes32 _relayer) public {
    require(msg.sender == governance, "unauthorized");
    require(isRelayer[_relayer], "The relayer does not exist");
    isRelayer[_relayer] = false;
    uint256 balance = balances[_relayer];
    if (balance > 0) {
      balances[_relayer] = 0;
      address addr = resolve(_relayer);
      require(torn.transfer(addr, balance), "TORN transfer failed");
    }
    emit RelayerRemoved(_relayer, balance);
  }

  function setStake(uint256 _stake) public {
    require(msg.sender == governance, "unauthorized");
    stake = _stake;
    emit StakeChanged(_stake);
  }
}
