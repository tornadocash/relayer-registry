//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../tornado-anonymity-mining/contracts/TornadoProxy.sol";
import "./RelayerRegistry.sol";

// TODO should we make it upgradable as well?
contract TornadoProxyV3 is TornadoProxy {
  RelayerRegistry public registry;

  constructor(
    address _tornadoTrees,
    address _governance,
    Tornado[] memory _instances,
    address _registry
  ) TornadoProxy(_tornadoTrees, _governance, _instances) {
    registry = RelayerRegistry(_registry);
  }

  function withdraw(
    ITornadoInstance _tornado,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) public payable override {
    super.withdraw(_tornado, _proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
    registry.transaction(msg.sender, _relayer);
  }
}
