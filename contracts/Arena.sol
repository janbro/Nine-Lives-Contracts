pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Interfaces/CryptoKittyInterface.sol";
import "./Interfaces/NineLivesInterface.sol";
import "./Interfaces/BattleInterface.sol";

contract Arena is Pausable {
    using SafeMath for uint256;

    event LogBattleResult(uint256 kittyWinner, uint kittyLoser);
    event LogKittyReadyToBattle(uint256 _kittyId);
    event LogKittyBattle(uint256 _kittyIdAttacker, uint256 _kittyIdDefender);
    event LogKittyWithdraw(uint256 _kittyId);
    event UpdateBattleContract(address _battleAddress);

    //Reward in ninelives token
    uint256 constant WIN_REWARD = 10;
    uint256 constant LOSS_REWARD = 4;
    address constant GRAVEYARD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 constant DEFENDER_BONUS_PER = 50; //Defender bonus percentage

    address public ckAddress = address(0x0);//0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
    CryptoKittyInterface kittyInterface;

    address nlAddress = address(0x0);
    NineLivesInterface nineLivesInterface;

    address battleAddress = address(0x0);
    BattleInterface battleInterface;

    mapping (uint256 => address) public kittyIndexToOwner;

    mapping (address => uint256) public rewards;

    /**
     * @dev Contructor
     */
    function Arena(address _nineLivesAddress, address _battleAddress, address _kCore)
        public
    {
        require(_nineLivesAddress != address(0x0));
        require(_battleAddress != address(0x0));
        require(_kCore != address(0x0));

        nlAddress = _nineLivesAddress;
        battleAddress = _battleAddress;
        ckAddress = _kCore;
        nineLivesInterface = NineLivesInterface(nlAddress);
        battleInterface = BattleInterface(battleAddress);
        kittyInterface = CryptoKittyInterface(ckAddress);

        paused = true;
    }

    /**
     * @dev Updates the battle contract address
     *
     * @param _battleAddress The new battle contracts address
     */
    function updateBattleContract(address _battleAddress)
        external
        onlyOwner
    {
        require(_battleAddress != address(0x0));
        battleAddress = _battleAddress;
        battleInterface = BattleInterface(battleAddress);
        UpdateBattleContract(_battleAddress);
    }

    /**
     * @dev Sends a kitty to battle specified kitty in the arena
     *
     * @param _kittyId The kitty's id
     * @param _kittyToBattle The defending kitty's id (ready to battle in the arena)
     */
    function sendKittyToBattle(uint256 _kittyId, uint256 _kittyToBattle)
        external
        whenNotPaused
        isOwnerOf(_kittyId)
    {
        //Check arena is approved to transfer kitty
        require(kittyInterface.kittyIndexToApproved(_kittyId) == address(this));

        //Ensure kitty to battle is ready to battle
        require(nineLivesInterface.isReadyToBattle(_kittyToBattle));

        //Save the owner so we can send the kitty back
        kittyIndexToOwner[_kittyId] = msg.sender;

        kittyInterface.transferFrom(msg.sender, address(this), _kittyId);

        _battle(_kittyId, _kittyToBattle);

        LogKittyBattle(_kittyId, _kittyToBattle);
    }

    /**
     * @dev Sends a kitty to the arena and sets it ready to battle
     *
     * @param _kittyId The kitty's id
     */
    function sendKittyReadyToBattle(uint256 _kittyId)
        external
        whenNotPaused
        isOwnerOf(_kittyId)
    {
        //Check arena is approved to transfer kitty
        require(kittyInterface.kittyIndexToApproved(_kittyId) == address(this));

        //Save the owner so we can send the kitty back
        kittyIndexToOwner[_kittyId] = msg.sender;

        kittyInterface.transferFrom(msg.sender, address(this), _kittyId);

        nineLivesInterface.setIsReadyToBattle(_kittyId, true);

        LogKittyReadyToBattle(_kittyId);
    }

    /**
     * Changes ownership of the passed kitty back to its owner. Used if a owner wants to remove kitty from ready to battle listing or to recover kitty from arena contract
     *
     * @param _kittyId The kitty's id
     */
    function withdrawKitty(uint _kittyId)
        external
    {
        require(kittyIndexToOwner[_kittyId] == msg.sender);
        kittyIndexToOwner[_kittyId] = 0;

        //Clear transferFrom rights from the arena contract
        kittyInterface.approve(address(0), _kittyId);

        nineLivesInterface.setIsReadyToBattle(_kittyId, false);

        //Transfer the kitty back to the owner
        kittyInterface.transfer(msg.sender, _kittyId);
        
        LogKittyWithdraw(_kittyId);
    }

    /**
     * @dev Rescues kitties if something goes horribly wrong
     */
    function rescueKitty(uint256 _kittyId)
        external
        onlyOwner
    {
        //Clear transferFrom rights from the arena contract
        kittyInterface.approve(address(0), _kittyId);

        nineLivesInterface.setIsReadyToBattle(_kittyId, false);

        //Transfer the kitty back to the owner
        kittyInterface.transfer(msg.sender, _kittyId);
        
        LogKittyWithdraw(_kittyId);
    }

    /**
     * @dev Withdraws the users total token rewards from the arena 
     */
    function withdrawRewards()
        external
    {
        require(rewards[msg.sender] > 0);

        uint _reward = rewards[msg.sender];
        rewards[msg.sender] = 0;

        //TODO: Add reward amount to token contract
    }

    /**
     * @dev Internal function where battle winner is determined. Calculated reward and sends kitty's back to owners
     * requires kitty's are owned by arena contract
     *
     * @param _kittyIdAttacker The attacking kitty's id
     * @param _kittyIdDefender The kitty who was ready to battle in the arena
     */
    function _battle(uint _kittyIdAttacker, uint _kittyIdDefender)
        internal
        whenNotPaused
    {
        assert(kittyInterface.ownerOf(_kittyIdAttacker) == address(this));
        assert(kittyInterface.ownerOf(_kittyIdDefender) == address(this));

        uint256 winnerId = battleInterface.doBattle(_kittyIdAttacker, _kittyIdDefender);

        if(winnerId == _kittyIdAttacker) {
            //Attacker won
            rewards[kittyIndexToOwner[_kittyIdAttacker]] = rewards[kittyIndexToOwner[_kittyIdAttacker]].add(WIN_REWARD);
            rewards[kittyIndexToOwner[_kittyIdDefender]] = rewards[kittyIndexToOwner[_kittyIdDefender]].add(LOSS_REWARD).add(LOSS_REWARD.mul(DEFENDER_BONUS_PER).div(100));
            nineLivesInterface.decrementLives(_kittyIdDefender);
            LogBattleResult(_kittyIdAttacker, _kittyIdDefender);
        }
        else {
            //Defender won
            rewards[kittyIndexToOwner[_kittyIdAttacker]] = rewards[kittyIndexToOwner[_kittyIdAttacker]].add(LOSS_REWARD);
            rewards[kittyIndexToOwner[_kittyIdDefender]] = rewards[kittyIndexToOwner[_kittyIdDefender]].add(WIN_REWARD).add(WIN_REWARD.mul(DEFENDER_BONUS_PER).div(100));
            nineLivesInterface.decrementLives(_kittyIdAttacker);
            LogBattleResult(_kittyIdDefender, _kittyIdAttacker);
        }

        _finishedBattling(_kittyIdAttacker);

        _finishedBattling(_kittyIdDefender);
    }

    /**
     * @dev Returns ownership of kitty to original owner. Resets battling state
     *
     * @param _kittyId The kitty's id
     */
    function _finishedBattling(uint _kittyId)
        internal
    {
        if(nineLivesInterface.getKittyLives(_kittyId) == 1) {
            kittyInterface.transfer(GRAVEYARD_ADDRESS, _kittyId);
        }
        else {
            nineLivesInterface.setIsReadyToBattle(_kittyId, false);
        }
    }

    /**
     * @dev Checks ownership of kitty
     *
     * @param _kittyId The kitty's id
     */
    modifier isOwnerOf(uint _kittyId) {
        require(kittyInterface.ownerOf(_kittyId) == msg.sender);
        _;
    }

}