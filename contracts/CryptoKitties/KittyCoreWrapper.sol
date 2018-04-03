pragma solidity ^0.4.19;

import "./KittyCore.sol";

contract KittyCoreWrapper is KittyCore {

    mapping (uint256 => uint256) public mmu;

    function MMU(uint256 _virtualAddress) internal view returns (uint256) {
        if(mmu[_virtualAddress] != 0)
            return mmu[_virtualAddress];
        return _virtualAddress;
    }

    /// @dev we can create promo kittens, up to a limit. Only callable by COO
    /// @param _genes the encoded genes of the kitten to be created, any value is accepted
    /// @param _owner the future owner of the created kittens. Default to contract COO
    function createPromoKittyId(uint256 _kittyId, uint256 _genes, address _owner) external onlyCOO {
        address kittyOwner = _owner;
        if (kittyOwner == address(0)) {
            kittyOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createKittyId(_kittyId, 0, 0, 0, _genes, kittyOwner);
    }

    /// @dev An internal method that creates a new kitty and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _matronId The kitty ID of the matron of this cat (zero for gen0)
    /// @param _sireId The kitty ID of the sire of this cat (zero for gen0)
    /// @param _generation The generation number of this cat, must be computed by caller.
    /// @param _genes The kitty's genetic code.
    /// @param _owner The inital owner of this cat, must be non-zero (except for the unKitty, ID 0)
    function _createKittyId(
        uint256 _virtualId,
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        uint physicalId = _createKitty(_matronId, _sireId, _generation, _genes, _owner);
        mmu[_virtualId] = physicalId;
        return _virtualId;
    }

    /// @notice Transfers a Kitty to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  CryptoKitties specifically) or your Kitty may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Kitty to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of kitties
        // through the allow + transferFrom flow.
        //require(_to != address(saleAuction));
        //require(_to != address(siringAuction));

        // You can only send your own cat.
        require(_owns(msg.sender, MMU(_tokenId)));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, MMU(_tokenId));
    }

    /// @notice Grant another address the right to transfer a specific Kitty via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Kitty that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, MMU(_tokenId)));

        // Register the approval (replacing any previous approval).
        _approve(MMU(_tokenId), _to);

        // Emit approval event.
        Approval(msg.sender, _to, MMU(_tokenId));
    }

    /// @notice Transfer a Kitty owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Kitty to be transfered.
    /// @param _to The address that should take ownership of the Kitty. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Kitty to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, MMU(_tokenId)));
        require(_owns(_from, MMU(_tokenId)));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, MMU(_tokenId));
    }

    /// @notice Returns the address currently assigned ownership of a given Kitty.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = kittyIndexToOwner[MMU(_tokenId)];

        require(owner != address(0));
    }

}