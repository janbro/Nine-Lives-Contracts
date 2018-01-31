pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./ERC721.sol";

contract AccesoryToken is ERC721, Pausable {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public name = "NineLivesAccessory";
    string public symbol = "NLA";

    uint256 total = 0;

    mapping (address => uint256) addressToBalance;
    mapping (uint256 => address) tokenToOwner;
    mapping (uint256 => address) tokenToApproved;
    mapping (address => uint256) ownershipTokenCount;
    Accessory[] accessories;

    struct Accessory {
        uint svgHash;
        uint16 x;
        uint16 y;
    }


    function implementsERC721() public pure returns (bool)
    {
        return true;
    }

    /** 
     * @dev ERC721 required method. Returns the total supply
     * @return uint256
     */
    function totalSupply()
        public
        view
        returns (uint256 total)
    {
        return total;
    }

    /** 
     * ERC721 required method. Returns balance of address
     * @param _owner address of balance owner
     * @return uint256
     */
    function balanceOf(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return addressToBalance[_owner];
    }

    /** 
     * ERC721 required method. Returns owner of accessory
     * @param _tokenId accessory id
     * @return address
     */
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        return tokenToOwner[_tokenId];
    }

    /** 
     * ERC721 required method. Approves address to use transferFrom with passed accessory
     * @param _to Address to approve
     * @param _tokenId accessory id
     */
    function approve(address _to, uint256 _tokenId)
        external
    {
        require(_owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

    /** 
     * ERC721 required method. Transfers accessory to passed address
     */
    function transfer(address _to, uint256 _tokenId)
        external
    {
        require(_owns(msg.sender, _tokenId));
        
        _transfer(msg.sender, _to, _tokenId);
    }

    /** 
     * @dev Required for ERC-721 compliance.
     * @param _from The address that owns the accessory
     * @param _to The address that takes ownership of the accessory
     * @param _tokenId accessory id
     */ 
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }



    /**
     * @dev Checks if claimant owns token
     * @param _claimant the address we are validating against.
     * @param _tokenId accessory id
     */
    function _owns(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return tokenToOwner[_tokenId] == _claimant;
    }

    /**
     * @dev Checks if claimant has transferApproval for token
     * @param _claimant the address 
     * @param _tokenId accessory id
     */
    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return tokenToApproved[_tokenId] == _claimant;
    }

    /**
     * @dev set approved address for transferFrom()
     * @param _tokenId accessory id
     * @param _approved address to approve
     */
    function _approve(uint256 _tokenId, address _approved)
        internal
    {
        tokenToApproved[_tokenId] = _approved;
    }

    /**
     * @dev Internal function to transfer tokens. Does not check ownership
     */
    function _transfer(address _from, address _to, uint256 _tokenId)
        internal
    {
        ownershipTokenCount[_to]++;
        ownershipTokenCount[_from]--;

        tokenToOwner[_tokenId] = _to;
        
        // Clear any approvals
        _approve(_tokenId, address(0x0));
        
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Internal function to create an accessory given its starting price, svg hash, and positioning
     * Newly created accessories start off as owned by the accessory store
     * @param _svgHash Keccak256 hash of svg file
     * @param _x x position of accessory
     * @param _y y position of accessory
     * @param _owner Owner of the created accessory
     */
    function _createAccessory(uint _svgHash, uint16 _x, uint16 _y, address _owner)
        internal
        returns (uint)
    {
        Accessory memory _accessory = Accessory({
            svgHash: _svgHash,
            x: _x,
            y: _y
        });

        uint256 accessoryId = accessories.push(_accessory) - 1;

        _transfer(0, _owner, accessoryId);

        return accessoryId;
    }

}