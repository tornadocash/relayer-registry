/* global ethers */
const { expect } = require('chai')

describe('RelayerRegistry', function () {
  const TornAddress = '0x77777FeDdddFfC19Ff86DB637967013e6C6A116C'

  it('Should deploy', async function () {
    const RelayerRegistry = await ethers.getContractFactory('RelayerRegistry')
    const relayerRegistry = await RelayerRegistry.deploy(TornAddress)
    await relayerRegistry.deployed()

    expect(await relayerRegistry.TORN()).to.equal(TornAddress)
  })
})
