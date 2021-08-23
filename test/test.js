const { expect } = require('chai')
const { ethers } = require('hardhat')
const { utils } = ethers

const { getSignerFromAddress, advanceTime } = require('./utils')

describe('Proposal', function () {
  this.timeout(200000)
  const tornAddress = '0x77777FeDdddFfC19Ff86DB637967013e6C6A116C'
  const governanceAddress = '0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce'
  const eip2470Address = '0xCEe71753C9820f063b38FDbE4cFDAf1d3D928A80'
  const relayerRegistryImpl = '0xE9c171C583115282fe1ed6e93E7b1b8aE758Ed51'
  const SALT = '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  let proposal, tornWhale, governance, torn, relayerRegistry, tornadoProxyV3

  /* prettier-ignore */
  before(async function () {
    governance = await ethers.getContractAt(require('./abi/governance.json'), governanceAddress)
    const VOTING_DELAY = (await governance.VOTING_DELAY()).toNumber()
    const VOTING_PERIOD = (await governance.VOTING_PERIOD()).toNumber()
    const EXECUTION_DELAY = (await governance.EXECUTION_DELAY()).toNumber()
    torn = await ethers.getContractAt(require('./abi/torn.json'), tornAddress)
    tornWhale = await getSignerFromAddress('0xF977814e90dA44bFA03b6295A0616a897441aceC')
    const Proposal = await ethers.getContractFactory('Proposal')
    proposal = await Proposal.deploy()

    expect(await proposal.isContract('0xE9c171C583115282fe1ed6e93E7b1b8aE758Ed51')).to.be.false

    const eip2770 = await ethers.getVerifiedContractAt(eip2470Address)
    const RelayerRegistry = await ethers.getContractFactory('RelayerRegistry')
    const receipt = await eip2770.deploy(RelayerRegistry.bytecode, SALT)
    const receiptEvents = await receipt.wait()
    expect(relayerRegistryImpl).to.be.equal(receiptEvents.events[0].args.addr) // this address will be different if you change the Relayer Registry contract
    expect(await proposal.isContract(relayerRegistryImpl)).to.be.true

    torn = torn.connect(tornWhale)
    governance = governance.connect(tornWhale)

    await torn.approve(governance.address, utils.parseEther('25000'))
    await governance.lockWithApproval(utils.parseEther('25000'))
    await governance.propose(proposal.address, 'Relayer registry')
    const proposalId = await governance.proposalCount()
    await advanceTime(VOTING_DELAY + 1)
    await governance.castVote(proposalId, true)
    await advanceTime(VOTING_PERIOD + EXECUTION_DELAY)

    const executeReceipt = await governance.execute(proposalId)
    const { events, gasUsed } = await executeReceipt.wait()
    console.log('Proposal execution took', gasUsed.toNumber())

    // eslint-disable-next-line no-unused-vars
    let [registryProxyAddr, tornadoProxyV3Addr] = events
      .filter(e => e.topics[0] === '0x06633ee22fe8e793dec66ce36696e948bb0cc0d018ab361e8dfeb34151a4d466')
      .map((e) => ethers.utils.getAddress('0x' + e.data.slice(90, 130)))
    relayerRegistry = RelayerRegistry.attach(registryProxyAddr)

    const TornadoProxyV3 = await ethers.getContractFactory('TornadoProxyV3')
    tornadoProxyV3 = TornadoProxyV3.attach(tornadoProxyV3Addr)
  })

  it('constructors', async function () {
    expect(await relayerRegistry.withdrawalProxy()).to.equal(tornadoProxyV3.address)

    const RelayerRegistry = await ethers.getContractFactory('RelayerRegistry')
    const relayerRegistryImplementation = RelayerRegistry.attach(relayerRegistryImpl)
    expect(await relayerRegistryImplementation.withdrawalProxy()).to.equal(
      '0x0000000000000000000000000000000000000000',
    )
  })
})
