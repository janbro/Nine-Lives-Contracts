pragma solidity ^0.4.19;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract NineLives is Pausable {
    using SafeMath for uint256;

    event LogKittySpawned(uint256 _kittyId);
    event LogWeiRateChanged(uint256 _newRate);
    event LogIsReadyToBattle(uint256 _kittyId, bool _state);
    event LogDecrementedKittyLife(uint256 _kittyId, uint8 _lives);
    event LogUpdatedArenaContract(address _newArenaAddress);
    
    mapping (uint256 => Kitty) public liveKitties;
    mapping (address => uint256) public pendingReturns;

    uint256[] public kittyIds;

    uint256 public weiPerSpawn;

    address private arenaContract;

    function NineLives(uint256 _weiPerSpawn) public {
        weiPerSpawn = _weiPerSpawn;
        paused = true;
    }
    
    struct Kitty {
        uint256 id;
        uint8 lives;
        bool isReadyToBattle;
    }

    function updateArenaContract(address _arenaContract)
        external
        onlyOwner
    {
        require(_arenaContract != address(0));
        arenaContract = _arenaContract;
        LogUpdatedArenaContract(arenaContract);
    }

    /**
     * @dev Updates the wei per kitty spawn
     * @param _weiPerSpawn The amount to spawn a kitty in wei
     */
    function updateWeiPerSpawn(uint256 _weiPerSpawn)
        external
        onlyOwner
    {
        weiPerSpawn = _weiPerSpawn;
        LogWeiRateChanged(weiPerSpawn);
    }

    /**
     * @dev default payable function when sending ether to this contract
     * Does not spawn kitties, users have to call spawnKitty and pass their kitty id
     */
    function () external payable {
        pendingReturns[msg.sender] = pendingReturns[msg.sender].add(msg.value);
    }
   
   /**
    * @dev Spawns a kitty if it hasn't already been spawned before 
    * @param _id The id of the kitty being spawned
    */
    function spawnKitty(uint256 _id)
        external
        payable
        whenNotPaused
    {
        require(liveKitties[_id].id == 0);
        require(msg.value >= weiPerSpawn);

        Kitty storage kitty = liveKitties[_id];
        kitty.id = _id;
        kitty.lives = 10;
        kitty.isReadyToBattle = false;
        kittyIds.push(_id);

        LogKittySpawned(_id);

        //Keep track of user's overpayments so they can recover
        uint256 refund = msg.value.sub(weiPerSpawn);
        pendingReturns[msg.sender] = pendingReturns[msg.sender].add(refund);
    }

    /**
     * @dev Alows user to collect overpayment
     */
    function withdrawRefund()
        external
    {
        uint256 amount = pendingReturns[msg.sender];

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
        returns (bool)
    {
        return liveKitties[_id].isReadyToBattle;
    }

    
    /**
     * @dev Changes kitties battle state
     * @param _id The kitty's id
     * @param _isReadyToBattle Boolean to set the battle state to
     */
    function setIsReadyToBattle(uint256 _id, bool _isReadyToBattle) 
        external
        kittyExists(_id) 
        onlyArena
        whenNotPaused
    {
        
        liveKitties[_id].isReadyToBattle = _isReadyToBattle;
        LogIsReadyToBattle(_id, liveKitties[_id].isReadyToBattle);
    }
    
    /**
     * @dev Decrements the lives of a kitty by 1
     * @param _id The kitty's id
     */
    function decrementLives(uint256 _id)
        external
        kittyExists(_id)
        onlyArena
        whenNotPaused
    {
        if(liveKitties[_id].lives > 1)
            liveKitties[_id].lives--;
        LogDecrementedKittyLife(_id, liveKitties[_id].lives);
    }

    function withdrawFunds()
        external
        onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }

    /**
     * @dev Checks the passed kitty has been spawned
     */
    modifier kittyExists(uint256 _kittyId) {
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