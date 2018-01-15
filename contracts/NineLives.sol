pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract NineLives is Pausable {
    using SafeMath for uint256;

    event LogKittySpawned(uint _kittyId);
    
    mapping (uint => Kitty) public liveKitties;
    mapping (address => uint) public pendingReturns;

    uint[] public kittyIds;

    uint public weiPerSpawn;

    address private arenaContract;

    function NineLives(uint _weiPerSpawn) public {
        weiPerSpawn = _weiPerSpawn;
    }
    
    struct Kitty {
        uint256 id;
        uint8 lives;
        bool isBattling;
        bool isReadyToBattle;
    }

    function updateArenaContract(address _arenaContract)
        external
        onlyOwner
    {
        require(_arenaContract != address(0));
        arenaContract = _arenaContract;
    }

    /**
     * @dev Updates the wei per kitty spawn
     * @param _weiPerSpawn The amount to spawn a kitty in wei
     */
    function updateWeiPerSpawn(uint _weiPerSpawn)
        external
        onlyOwner
    {
        weiPerSpawn = _weiPerSpawn;
    }

    // default payable function when sending ether to this contract
    function () external payable {
        pendingReturns[msg.sender] = pendingReturns[msg.sender].add(msg.value);
    }
   
   /**
    * @dev Spawns a kitty if it hasn't already been spawned before 
    * @param _id The id of the kitty being spawned
    */
    function spawnKitty(uint _id)
        external
        payable
        whenNotPaused
    {
        require(liveKitties[_id].id == 0);
        require(msg.value >= weiPerSpawn);

        var kitty = liveKitties[_id];
        kitty.id = _id;
        kitty.lives = 10;
        kitty.isBattling = false;
        kittyIds.push(_id);

        LogKittySpawned(_id);

        //Keep track of user's overpayments so they can recover
        uint refund = msg.value.sub(weiPerSpawn);
        pendingReturns[msg.sender] = pendingReturns[msg.sender].add(refund);
    }

    /**
     * @dev Alows user to collect overpayment
     */
    function withdrawRefund()
        external
    {
        var amount = pendingReturns[msg.sender];

        require(amount > 0);

        pendingReturns[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns a kitty's properties
     * @param _id The kitty's id
     */ 
    function getKittyInfo(uint _id)
        external
        view
        kittyExists(_id)
        returns (
            uint8 lives,
            bool isBattling
        )
    {
        return (liveKitties[_id].lives, liveKitties[_id].isBattling);
    }
   
    /**
     * @dev Returns the remaining lives of a kitty
     * @param _id The kitty's id
     */
    function getKittyLives(uint _id)
        external
        view
        kittyExists(_id)
        returns (uint8 lives) 
    {
        return liveKitties[_id].lives;
    }
    
    /**
     * @dev Returns if the kitty is ready for battle
     * @param _id The kitty's id
     */
    function isBattling(uint _id) 
        external
        view
        kittyExists(_id)
        returns (bool isBattling)
    {
        return liveKitties[_id].isBattling;
    }

    /**
     * @dev Returns if the kitty is ready for battle
     * @param _id The kitty's id
     */
    function isReadyToBattle(uint _id) 
        external
        view
        kittyExists(_id)
        returns (bool isReadyToBattle)
    {
        return liveKitties[_id].isReadyToBattle;
    }
    
    /**
     * @dev Changes kitties battle state
     * @param _id The kitty's id
     * @param _isBattling Boolean to set the battle state to
     */
    function setBattling(uint _id, bool _isBattling) 
        external
        kittyExists(_id) 
        onlyArena
        whenNotPaused
    {
        
        liveKitties[_id].isBattling = _isBattling;
    }

    
    /**
     * @dev Changes kitties battle state
     * @param _id The kitty's id
     * @param _isBattling Boolean to set the battle state to
     */
    function setIsReadyToBattle(uint _id, bool _isReadyToBattle) 
        external
        kittyExists(_id) 
        onlyArena
        whenNotPaused
    {
        
        liveKitties[_id].isReadyToBattle = _isReadyToBattle;
    }
    
    /**
     * @dev Decrements the lives of a kitty by 1
     * @param _id The kitty's id
     */
    function decrementLives(uint _id)
        external
        kittyExists(_id)
        onlyArena
        whenNotPaused
    {
        require(liveKitties[_id].lives > 1);
        
        liveKitties[_id].lives--;
    }

    function withdrawFunds()
        external
        onlyOwner
    {
        msg.sender.transfer(this.balance);
    }

    /**
     * @dev Checks the passed kitty has been spawned
     */
    modifier kittyExists(uint _kittyId) {
        require(liveKitties[_kittyId].id != 0);
        _;
    }

    /**
     * @dev Checks the caller is the arena contract
     */
    modifier onlyArena() {
        require(msg.sender == arenaContract);
        _;
    }
}