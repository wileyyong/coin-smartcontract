// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Pumlx.sol";


contract PumlStake is Ownable, ReentrancyGuard {

    IERC20 _puml;
    PUMLx public _pumlxPool;
    PUMLx public _nftPool;

    constructor(address _pumlxPoolAddress, address _nftPoolAddress) {
        _puml = IERC20(0xB2e408bc3E7674De7c589F4f8E5471C81F09F5c6);
        _pumlxPool = PUMLx(_pumlxPoolAddress);
        _nftPool = PUMLx(_nftPoolAddress);
    }

    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public userLastUpdateTime;
    mapping(address => uint256) public userLastUpdateTimeNFT;
    mapping(address => uint256) public userReward;
    mapping(address => uint256) public userLastReward;
    mapping(address => uint256) public userCollect;
    mapping(address => uint256) public userLastCollect;

    uint256 public totalSupply;
    uint256 public totalSupplyNFT;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public balancesNFT;
    /*mapping(uint256 => address) public stakedAssets;*/
    mapping(address => mapping(uint256 => address)) public stakedAssets;

    struct UserData {
        uint256 userLastUpdateTime;
        uint256 userLastUpdateTimeNFT;
        uint256 balances;
        uint256 totalBalances;
        uint256 balancesNFT;
        uint256 totalBalancesNFT;
        uint256 userReward;
        uint256 userLastReward;
        uint256 userCollect;
        uint256 userLastCollect;
    }

    /* ========== VIEWS ========== */

    function getStakedAssets(address _contractAddress, uint256 _tokenId) public view returns (address) {
        return stakedAssets[_contractAddress][_tokenId];
    }

    function setStakedAssets(address _contractAddress, uint256 _tokenId, address _staker) public {
        stakedAssets[_contractAddress][_tokenId] = _staker;
    }

    function setBalancesNFT(address _address, uint256 _amount, bool param) public {
        if (param) {
            balancesNFT[_address] += _amount;
            if (balancesNFT[_address] == _amount) {
               userLastUpdateTimeNFT[_address] = lastTimeRewardApplicable(); 
            }
            totalSupplyNFT += _amount;
        } else {
            balancesNFT[_address] -= _amount;
            totalSupplyNFT -= _amount;
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp;
    }

    function getUserData(address account) public view returns (UserData memory) {
        UserData memory userdata = UserData({
            userLastUpdateTime: userLastUpdateTime[account],
            userLastUpdateTimeNFT: userLastUpdateTimeNFT[account],
            balances: balances[account],
            totalBalances: totalSupply,
            balancesNFT: balancesNFT[account],
            totalBalancesNFT: totalSupplyNFT,
            userReward: userReward[account],
            userLastReward: userLastReward[account],
            userCollect: userCollect[account],
            userLastCollect: userLastCollect[account]
        });

        return userdata;
    }

    function setTransferPuml(address _from, address _to, uint256 _amount) public {
        require(_amount > 0, "You need to transfer at least some tokens");
        _puml.transferFrom(_from, _to, _amount);
    }

    function setDepositPuml(address _from, uint256 _amount) public {
        require(_amount > 0, "You need to deposite at least some tokens");
        _puml.transferFrom(_from, address(this), _amount);
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount, uint256 stakeamount) external payable nonReentrant {
        _stake(amount, msg.sender);
        emit Staked(msg.sender, amount);

        _puml.transferFrom(msg.sender, address(this), stakeamount);
    }

    function withdraw(uint256 amount, uint256 unstakeamount, uint256 claimAmount) public payable nonReentrant {

        _withdraw(amount);
        userReward[msg.sender] += claimAmount;
        userLastReward[msg.sender] = claimAmount;

        emit Withdrawn(msg.sender, amount);
        emit RewardPaid(msg.sender, claimAmount);

        _puml.transfer(msg.sender, unstakeamount);
        _pumlxPool.transferPuml(msg.sender, claimAmount);
    }

    function collectNftReward(uint256 collectAmount) public payable nonReentrant {
        userCollect[msg.sender] += collectAmount;
        userLastCollect[msg.sender] = collectAmount;

        _nftPool.transferPuml(msg.sender, collectAmount);
        emit RewardPaid(msg.sender, collectAmount);
    }

    function claimApi(address claimer, uint256 reward) public payable nonReentrant {
        if (reward > 0) { 
            _pumlxPool.transferPuml(claimer, reward);
            emit RewardPaid(claimer, reward);
        }
    }

    function _stake(uint256 _amount, address _staker) internal {
        totalSupply += _amount;
        balances[_staker] += _amount;
        if (balances[_staker] == _amount) {
            userLastUpdateTime[_staker] = lastTimeRewardApplicable();
        }
    }

    function _withdraw(uint256 _amount) internal {
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
    }

    function transferPuml(address _to, uint256 _amount) public payable nonReentrant {
        require(_amount > 0, "You need to transfer at least some tokens");
        _puml.transferFrom(msg.sender, _to, _amount);
    }

    function pickPuml(address _to, uint256 _amount) public payable nonReentrant {
        require(_amount > 0, "You need to transfer at least some tokens");
        _puml.transfer(_to, _amount);
    }

    function depositPuml(uint256 _amount) public payable nonReentrant {
        require(_amount > 0, "You need to deposite at least some tokens");
        _puml.transferFrom(msg.sender, address(this), _amount);
    }

    
    /* ========== EVENTS ========== */


    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
