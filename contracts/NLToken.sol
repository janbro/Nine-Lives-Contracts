pragma solidity ^0.4.19;

import '../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract NLToken is MintableToken {

    address external_minter = address(0x0);

    function NLToken(address _arena_address) public {
        external_minter = _arena_address;
    }

    function isMintableToken() 
        external
        pure
        returns (bool)
    {
        return true;
    }

    function externalMint(address _to, uint256 _amount)
        public
        onlyMinter        
        returns (bool)
    {
        return mint(_to, _amount);
    }


    modifier onlyMinter() {
        require(msg.sender == external_minter);
        _;
    }

}