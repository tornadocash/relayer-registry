// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract RelayerRegistry {
  address public immutable governance;
  mapping(bytes32 => bool) public isRelayer;

  event RelayerAdded(bytes32 indexed relayer);
  event RelayerRemoved(bytes32 indexed relayer);

  modifier onlyGovernance() {
    require(msg.sender == governance, "unauthorized");
    _;
  }

  constructor(address _governance) public {
    governance = _governance;
  }

  function add(bytes32 _relayer) public onlyGovernance {
    require(!isRelayer[_relayer], "The relayer already exists");
    isRelayer[_relayer] = true;
    emit RelayerAdded(_relayer);
  }

  function remove(bytes32 _relayer) public onlyGovernance {
    require(isRelayer[_relayer], "The relayer does not exist");
    isRelayer[_relayer] = false;
    emit RelayerRemoved(_relayer);
  }
}
