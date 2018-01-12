pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract NineLives is Pausable {

    event KittySpawned(uint _kittyId);

    using SafeMath for uint256;
    
    mapping (uint => Kitty) public liveKitties;
    mapping (address => uint) public pendingReturns;

    uint[] public kittyIds;

    uint public weiPerSpawn;

    address private arenaContract;

    function NineLives(address _arenaContract, uint _weiPerSpawn) public {
        arenaContract = _arenaContract;
        weiPerSpawn = _weiPerSpawn;
    }
    
    struct Kitty {
        uint256 id;
        uint8 lives;
        bool isReadyToBattle;
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
        kitty.isReadyToBattle = false;
        kittyIds.push(_id);

        KittySpawned(_id);

        //Keep track of user's overpayments so they can recover
        uint refund = msg.value.sub(weiPerSpawn);
        pendingReturns[msg.sender] = pendingReturns[msg.sender].add(refund);
    }

    /**
     * @dev Alows user to collect overpayment
     */
    function withdrawRefund()
        external
        returns (bool)
    {
        var amount = pendingReturns[msg.sender];

        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
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
            bool isReadyToBattle
        )
    {
        return (liveKitties[_id].lives, liveKitties[_id].isReadyToBattle);
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
    function isReadyToBattle(uint _id) 
        external
        view
        kittyExists(_id)
        returns (bool isReady)
    {
        return liveKitties[_id].isReadyToBattle;
    }
    
    /**
     * @dev Changes kitties battle state
     * @param _id The kitty's id
     * @param _isReadyToBattle Boolean to set the battle state to
     */
    function setReadyToBattle(uint _id, bool _isReadyToBattle) 
        external
        kittyExists(_id) 
        onlyArena
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
    {
        require(liveKitties[_id].lives > 1);
        
        liveKitties[_id].lives--;
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