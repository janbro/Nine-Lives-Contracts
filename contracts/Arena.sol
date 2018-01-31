pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./CryptoKittyInterfaces/CryptoKittyInterface.sol";

contract NineLivesInterface {

    mapping (address => uint) public pendingReturns;

    uint[] public kittyIds;

    uint public weiPerSpawn;

    function getKittyInfo(uint _id) external view returns (uint8 lives, bool isReadyToBattle);
   
    function getKittyLives(uint _id) external view returns (uint8 lives);
    
    function isReadyToBattle(uint _id) external view returns (bool isReadyToBattle);

    function setIsReadyToBattle(uint _id, bool _isReadyToBattle) external;

    function decrementLives(uint _id) external;
}

contract Arena is Pausable {
    using SafeMath for uint256;

    event LogBattleResult(uint kittyWinner, uint kittyLoser);
    event LogKittyReadyToBattle(uint _kittyId);
    event LogKittyWithdraw(uint _kittyId);

    //Reward in ninelives token
    uint constant WIN_REWARD = 10;
    uint constant LOSS_REWARD = 4;
    address constant GRAVEYARD_ADDRESS = address(0x0);

    uint constant DEFENDER_BONUS_PER = 50; //Defender bonus percentage

    address ckAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    CryptoKittyInterface kittyInterface = CryptoKittyInterface(ckAddress);

    address nlAddress = 0x0;
    NineLivesInterface nineLivesInterface = NineLivesInterface(nlAddress);

    mapping (uint => address) kittyIndexToOwner;

    mapping (address => uint) rewards;

    /**
     * @dev Sends a kitty to battle specified kitty in the arena
     *
     * @param _kittyId The kitty's id
     * @param _kittyToBattle The defending kitty's id (ready to battle in the arena)
     */
    function sendKittyToBattle(uint _kittyId, uint _kittyToBattle)
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
    }

    /**
     * @dev Sends a kitty to the arena and sets it ready to battle
     *
     * @param _kittyId The kitty's id
     */
    function sendKittyReadyToBattle(uint _kittyId)
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
        whenNotPaused
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
    {
        assert(kittyInterface.ownerOf(_kittyIdAttacker) == address(this));
        assert(kittyInterface.ownerOf(_kittyIdDefender) == address(this));

        uint8 winPercentageAttacker = 10;

        address attackerOwner = kittyIndexToOwner[_kittyIdAttacker];
        address defenderOwner = kittyIndexToOwner[_kittyIdDefender];

        uint[4] memory attackerStats;
        (,,,,, attackerStats[0], attackerStats[1], attackerStats[2], attackerStats[3],) = kittyInterface.getKitty(_kittyIdAttacker);

        uint[4] memory defenderStats;
        (,,,,, defenderStats[0], defenderStats[1], defenderStats[2], defenderStats[3],) = kittyInterface.getKitty(_kittyIdDefender);

        if(attackerStats[0] > defenderStats[0]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[0] == defenderStats[0]) {
            winPercentageAttacker += 10;
        }

        if(attackerStats[1] > defenderStats[1]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[1] == defenderStats[1]) {
            winPercentageAttacker += 10;
        }

        if(attackerStats[2] > defenderStats[2]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[2] == defenderStats[2]) {
            winPercentageAttacker += 10;
        }

        if(attackerStats[3] > defenderStats[3]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[3] == defenderStats[3]) {
            winPercentageAttacker += 10;
        }

        bool attackerWins = _randomNumber(0, 100) < winPercentageAttacker;

        if(attackerWins) {
            //Attacker won
            rewards[attackerOwner] = rewards[attackerOwner].add(WIN_REWARD);
            rewards[defenderOwner] = rewards[defenderOwner].add(LOSS_REWARD).add(LOSS_REWARD.mul(DEFENDER_BONUS_PER).div(100));
            nineLivesInterface.decrementLives(_kittyIdDefender);
            LogBattleResult(_kittyIdAttacker, _kittyIdDefender);
        }
        else {
            //Defender won
            rewards[attackerOwner] = rewards[attackerOwner].add(LOSS_REWARD);
            rewards[defenderOwner] = rewards[defenderOwner].add(WIN_REWARD).add(WIN_REWARD.mul(DEFENDER_BONUS_PER).div(100));
            nineLivesInterface.decrementLives(_kittyIdAttacker);
            LogBattleResult(_kittyIdDefender, _kittyIdAttacker);
        }

        _finishedBattling(_kittyIdAttacker);

        _finishedBattling(_kittyIdDefender);
    }

    /**
     * @dev Computes a random number based on the psuedorandom blockhash
     */
    function _randomNumber(uint _floor, uint _ceiling)
        internal
        view
        returns (uint)
    {
        require(_ceiling > _floor);
        
        return uint(block.blockhash(block.number-1))%(_ceiling.sub(_floor)).add(_floor);
    }

    /**
     * @dev Returns ownership of kitty to original owner. Resets battling state
     *
     * @param _kittyId The kitty's id
     */
    function _finishedBattling(uint _kittyId)
        internal
    {
        kittyIndexToOwner[_kittyId] = 0;

        if(nineLivesInterface.getKittyLives(_kittyId) == 1) {
            kittyInterface.transfer(GRAVEYARD_ADDRESS, _kittyId);
        }
        else {
            nineLivesInterface.setIsReadyToBattle(_kittyId, false);
        }
    }

    modifier isOwnerOf(uint _kittyId) {
        require(kittyInterface.ownerOf(_kittyId) == msg.sender);
        _;
    }

}