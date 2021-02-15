/* global artifacts, web3, contract */
require('chai').use(require('bn-chai')(web3.utils.BN)).use(require('chai-as-promised')).should()

const { takeSnapshot, revertSnapshot } = require('../scripts/ganacheHelper')
const { toBN } = require('web3-utils')
const Torn = artifacts.require('TornMock.sol')
const RelayerRegistry = artifacts.require('RelayerRegistryMock.sol')

contract('RelayerRegistry', (accounts) => {
  let registry
  let torn
  let snapshotId
  const relayer1 = accounts[5]

  before(async () => {
    torn = await Torn.new()
    await torn.transfer(accounts[5], '1000')
    registry = await RelayerRegistry.new(accounts[0], torn.address)
    snapshotId = await takeSnapshot()
  })

  describe('#add', () => {
    it('should work', async () => {
      const { logs } = await registry.add(relayer1)

      logs[0].event.should.be.equal('RelayerAdded')
      logs[0].args.relayer.should.be.equal((relayer1 + '000000000000000000000000').toLowerCase())
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

    it('should charge tokens', async () => {
      const relayerBalanceBefore = await torn.balanceOf(relayer1)
      relayerBalanceBefore.should.eq.BN(toBN(1000))
      const registryBalanceBefore = await torn.balanceOf(registry.address)
      registryBalanceBefore.should.eq.BN(toBN(0))

      const stake = toBN(1000)
      await torn.approve(registry.address, stake, { from: relayer1 })
      await registry.setStake(stake)
      await registry.add(relayer1)

      const relayerBalanceAfter = await torn.balanceOf(relayer1)
      relayerBalanceAfter.should.eq.BN(toBN(0))
      const registryBalanceAfter = await torn.balanceOf(registry.address)
      registryBalanceAfter.should.eq.BN(toBN(1000))
    })

    it('should fail when can not charge tokens', async () => {
      await registry.setStake(toBN(1000))
      await registry.add(relayer1).should.be.rejectedWith('ERC20: transfer amount exceeds allowance.')
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
      logs[0].args.relayer.should.be.equal((relayer1 + '000000000000000000000000').toLowerCase())
    })

    it('should prevent remove not existing', async () => {
      await registry.remove(relayer1).should.be.rejectedWith('The relayer does not exist')
    })

    it('should return tokens')
    it('should return correct token amount after stake change')
    it('should allow relayer to initiate exit')

  })

  describe('#setStake', () => {
    it('should work', async () => {
      const stakeBefore = await registry.stake()
      stakeBefore.should.eq.BN(0)

      const { logs } = await registry.setStake(toBN(1000))

      logs[0].event.should.be.equal('StakeChanged')
      logs[0].args.stake.should.be.eq.BN(toBN(1000))

      const stakeAfter = await registry.stake()
      stakeAfter.should.eq.BN(toBN(1000))
    })

    it('should prevent unauthorized access', async () => {
      await registry.setStake('1', { from: accounts[1] }).should.be.rejectedWith('unauthorized')
    })
  })

  afterEach(async () => {
    await revertSnapshot(snapshotId.result)
    // eslint-disable-next-line require-atomic-updates
    snapshotId = await takeSnapshot()
  })
})
