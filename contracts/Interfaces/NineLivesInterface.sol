pragma solidity ^0.4.18;

contract NineLivesInterface {

    mapping (address => uint256) public pendingReturns;

    uint256[] public kittyIds;

    uint256 public weiPerSpawn;

    function getKittyInfo(uint256 _id) external view returns (uint8 lives, bool isReadyToBattle);
   
    function getKittyLives(uint256 _id) external view returns (uint8 lives);
    
    function isReadyToBattle(uint256 _id) external view returns (bool isReadyToBattle);

    function setIsReadyToBattle(uint256 _id, bool _isReadyToBattle) external;

    function decrementLives(uint256 _id) external;
}