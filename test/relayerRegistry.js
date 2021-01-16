/* global artifacts, web3, contract */
require('chai').use(require('bn-chai')(web3.utils.BN)).use(require('chai-as-promised')).should()

const { takeSnapshot, revertSnapshot } = require('../scripts/ganacheHelper')
const RelayerRegistry = artifacts.require('./RelayerRegistry.sol')

contract('RelayerRegistry', (accounts) => {
  let registry
  let snapshotId
  const relayer1 = '0x3b43172e77b9e7272c8045d818f7ce325205bed01fb56a3747b78ae9c0ce4334'

  before(async () => {
    registry = await RelayerRegistry.new(accounts[0])
    snapshotId = await takeSnapshot()
  })

  describe('#add', () => {
    it('should work', async () => {
      const { logs } = await registry.add(relayer1)

      logs[0].event.should.be.equal('RelayerAdded')
      logs[0].args.relayer.should.be.equal(relayer1)
    })

    it('should prevent double add', async () => {
      await registry.add(relayer1)
      await registry.add(relayer1).should.be.rejectedWith('The relayer already exists')
    })

    it('should allow readd', async () => {
      await registry.add(relayer1)
      await registry.remove(relayer1)
      await registry.add(relayer1)
    })

    it('should prevent unauthorized access', async () => {
      await registry.add(relayer1, { from: accounts[1] }).should.be.rejectedWith('unauthorized')
    })
  })

  describe('#remove', () => {
    it('should work', async () => {
      await registry.add(relayer1)
      const { logs } = await registry.remove(relayer1)

      logs[0].event.should.be.equal('RelayerRemoved')
      logs[0].args.relayer.should.be.equal(relayer1)
    })

    it('should prevent remove not existing', async () => {
      await registry.remove(relayer1).should.be.rejectedWith('The relayer does not exist')
    })

    it('should prevent unauthorized access', async () => {
      await registry.add(relayer1)
      await registry.remove(relayer1, { from: accounts[1] }).should.be.rejectedWith('unauthorized')
    })
  })

  afterEach(async () => {
    await revertSnapshot(snapshotId.result)
    // eslint-disable-next-line require-atomic-updates
    snapshotId = await takeSnapshot()
  })
})
