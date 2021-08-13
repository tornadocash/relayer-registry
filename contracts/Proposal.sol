/*
This proposal introduces a registery for relayers where anyone can stake TORN and become relayer.

More info: https://torn.community/t/
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

import "./TornadoProxyV3.sol";
import "./RelayerRegistry.sol";

interface IProposal4 {
  function getInstances() external view returns (TornadoProxy.Tornado[] memory instances);
}

interface TornadoTrees is ITornadoTrees {
  function setTornadoProxyContract(address _tornadoProxy) external;
}

// TODO should we add SWAP and CLAIM operations here as well?
contract Proposal {
  TornadoProxy public constant tornadoProxyV2 = TornadoProxy(0x722122dF12D4e14e13Ac3b6895a86e84145b6967);
  TornadoTrees public constant tornadoTrees = TornadoTrees(0x527653eA119F3E6a1F5BD18fbF4714081D7B31ce);
  IProposal4 public constant proposal4 = IProposal4(0x4B6C07B8940a7602fE4332AFa915b366e56eAce5);
  address public constant governance = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
  uint256 public constant txFee = 0.01 ether;
  uint256 public constant minStake = 500 ether;

  event DeploymentOf(string name, address addr);

  function executeProposal() public {
    TornadoProxy.Tornado[] memory instances = getInstances();
    // disabling all instances on current tornadoProxy
    for (uint256 i = 0; i < instances.length; i++) {
      tornadoProxyV2.updateInstance(TornadoProxy.Tornado({
        addr: instances[i].addr,
        instance: TornadoProxy.Instance({
          isERC20: false,
          token: IERC20(0),
          state: TornadoProxy.InstanceState.DISABLED
        })
      }));
    }

    // deploying Relayer registry upgradable proxy and its implementation
    RelayerRegistry registry = new RelayerRegistry();
    TransparentUpgradeableProxy registryProxy = new TransparentUpgradeableProxy(address(registry), governance, "");

    // deploying the new tornadoProxy
    TornadoProxyV3 tornadoProxyV3 = new TornadoProxyV3(
      address(tornadoProxyV2.tornadoTrees()),
      tornadoProxyV2.governance(),
      instances,
      address(registryProxy)
    );

    // initializing Relayer registry
    registry = RelayerRegistry(address(registryProxy));
    registry.initialize(address(tornadoProxyV3), txFee, minStake);

    // registering the new tornadoProxy contract in tornadoTrees
    tornadoTrees.setTornadoProxyContract(address(tornadoProxyV3));
  }

  /// @dev Returns actuall all supported instances with actual state
  function getInstances() public view returns (TornadoProxy.Tornado[] memory instances) {
    instances = proposal4.getInstances();

    for(uint i = 0; i < instances.length; i++) {
      (bool isERC20, IERC20 token, TornadoProxy.InstanceState state) = tornadoProxyV2.instances(instances[i].addr);
      require(instances[i].instance.isERC20 == isERC20, "Incorrect instance state (isERC20)");
      require(instances[i].instance.token == token, "Incorrect instance token");
      instances[i].instance.state = state;
    }
  }
}
