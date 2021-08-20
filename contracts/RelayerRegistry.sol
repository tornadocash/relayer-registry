//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

interface IENS {
  function owner(bytes32 node) external view returns (address);
}

contract RelayerRegistry is Initializable {
  using SafeMath for uint256;

  IERC20 public constant TORN = IERC20(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);
  IENS public constant ENS = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
  address public constant GOV = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
  address public withdrawalProxy;

  mapping(address => Relayer) public relayers;
  uint256 public txFee; // TODO should rely on baseFee for a tx
  uint256 public minStake;
  uint256 public govFeeSplitPercent;
  uint256 public totalTornBurned;

  event Register(bytes32 ensHash, address relayer);
  event Stake(address indexed relayer, uint256 stake);
  event Kick(address indexed relayer, bool confiscation);
  event Transaction(address indexed relayer, uint fee);
  event NewMinStake(uint256 stake);
  event NewTxFee(uint256 fee);
  event NewWithdrawalProxy(address proxy);
  event NewGovFeeSplitPercent(uint256 govFeeSplitPercent);


  modifier onlyWithdrawalProxy {
    require(msg.sender == withdrawalProxy, "only withdrawal proxy");
    _;
  }

  modifier onlyGovernance {
    require(msg.sender == GOV, "only governance");
    _;
  }

  struct Relayer {
    uint256 balance;
    bytes32 ensHash;
    mapping(address => bool) addresses;
  }

  function initialize(address _withdrawalProxy, uint256 _txFee, uint256 _minStake, uint256 _govFeeSplitPercent) external initializer {
    withdrawalProxy = _withdrawalProxy;
    txFee = _txFee;
    minStake = _minStake;
    govFeeSplitPercent = _govFeeSplitPercent;
  }

  function register(uint _stake, bytes32 _ensHash) external {
    require(msg.sender == ENS.owner(_ensHash), "only owner of the ENS name");
    Relayer storage relayer = relayers[msg.sender];
    require(relayer.ensHash == bytes32(0) && _stake >= minStake);

    _updateStake(_stake, relayer);

    relayer.addresses[msg.sender] = true;
    relayer.ensHash = _ensHash;
    emit Register(_ensHash, msg.sender);
  }

  function stake(uint _stake) external {
    Relayer storage relayer = relayers[msg.sender];
    require(relayer.ensHash != bytes32(0), "Only registered relayers can top up balance");
    _updateStake(_stake, relayer);
  }


  function transaction(address _sender, address _feeReceiver) onlyWithdrawalProxy external {
    Relayer storage relayer = relayers[_feeReceiver];
    if(relayer.ensHash != bytes32(0)) {
      require(relayer.addresses[_sender], "only registered relayer can send");
      uint256 fee = relayer.balance > txFee ? txFee : relayer.balance;
      relayer.balance -= fee;
      totalTornBurned += fee;
      emit Transaction(_feeReceiver, fee);
    }
  }

  function distributeFees() external {
    uint _totalTornBurned = totalTornBurned;
    uint govAmount = totalTornBurned.mul(govFeeSplitPercent).div(100);
    TORN.transfer(GOV, govAmount);
    TORN.transfer(address(0), _totalTornBurned.sub(govAmount));
  }

  function setTxFee(uint256 _txFee) external onlyGovernance {
    txFee = _txFee;
    emit NewTxFee(_txFee);
  }

  function setMinStake(uint256 _stake) external onlyGovernance {
    minStake = _stake;
    emit NewMinStake(_stake);
  }

  function setWithdrawalProxy(address _proxy) external onlyGovernance {
    withdrawalProxy = _proxy;
    emit NewWithdrawalProxy(_proxy);
  }

  function setGovFeeSplitPercent(uint256 _govFeeSplitPercent) external onlyGovernance {
    require(_govFeeSplitPercent <= 100, "Percent should an integer number from 0 to 100");
    govFeeSplitPercent = _govFeeSplitPercent;
    emit NewGovFeeSplitPercent(_govFeeSplitPercent);
  }

  function kick(address _relayer, bool confiscateStake) external onlyGovernance {
    Relayer storage relayer = relayers[_relayer];
    TORN.transfer(confiscateStake ? msg.sender : _relayer, relayer.balance);
    relayer.balance = 0;
    emit Kick(_relayer, confiscateStake);
  }

  function _updateStake(uint _stake, Relayer storage relayer) private {
    TORN.transferFrom(msg.sender, address(this), _stake);
    relayer.balance = relayer.balance.add(_stake);
    emit Stake(msg.sender, _stake);
  }
}
