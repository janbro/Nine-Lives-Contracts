pragma solidity ^0.4.19;

import '../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract NLToken is MintableToken {

    address external_minter = address(0x0);
    string public constant name = "Nine Lives Token";
    string public constant symbol = "NLT";

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
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }


    modifier onlyMinter() {
        require(msg.sender == external_minter);
        _;
    }

}