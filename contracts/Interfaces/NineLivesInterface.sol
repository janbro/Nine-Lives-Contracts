pragma solidity ^0.4.19;

contract NineLivesInterface {

    mapping (address => uint256) public pendingReturns;

    uint256[] public kittyIds;

    uint256 public weiPerSpawn;

    function getKittyInfo(uint256 _id) external view returns (uint8 _lives, bool _isReadyToBattle);
   
    function getKittyLives(uint256 _id) external view returns (uint8 _lives);
    
    function isReadyToBattle(uint256 _id) external view returns (bool _isReadyToBattle);

    function setIsReadyToBattle(uint256 _id, bool _isReadyToBattle) external;

    function decrementLives(uint256 _id) external;

    function incrementWins(uint256 _id) external;
}