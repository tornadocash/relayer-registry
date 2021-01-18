// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TornMock is ERC20("TORN", "TORN") {
  constructor() public {
    _mint(msg.sender, 1e25);
  }
}
