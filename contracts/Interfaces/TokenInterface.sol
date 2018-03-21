pragma solidity ^0.4.19;

contract TokenInterface {

    function externalMint(address _to, uint256 _amount) public returns (bool);

    function isMintableToken() external returns (bool);

}