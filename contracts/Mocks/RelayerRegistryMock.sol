// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../RelayerRegistry.sol";

contract RelayerRegistryMock is RelayerRegistry {
  constructor(address _governance, IERC20 _torn) public RelayerRegistry(_governance, _torn) {}

  function resolve(bytes32 _addr) public override view returns (address) {
    return address(uint160(uint256(_addr) >> (12 * 8)));
  }
}
