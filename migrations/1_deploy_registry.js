/* global artifacts */
const RelayerRegistry = artifacts.require('RelayerRegistry')

module.exports = function (deployer, network, accounts) {
  return deployer.then(async () => {
    const registry = await deployer.deploy(RelayerRegistry, accounts[0])

    console.log('Registry      :', registry.address)
  })
}
