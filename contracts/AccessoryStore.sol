pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract AccessoryStore is Pausable {
    
    struct Sale {
        uint weiPrice;
        uint tokenId;    
    }

    Sale[] activeSales;

    function _createAuction(uint256 _tokenId, uint256 _price)
        external
        onlyOwner
        whenNotPaused
    {
        
    }

    function _createAuctions(uint[] _tokenIds, uint256 _price)
        external
        onlyOwner
        whenNotPaused
    {

    }

}