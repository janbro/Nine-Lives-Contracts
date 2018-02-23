pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./Interfaces/CryptoKittyInterface.sol";

contract Battle {
    using SafeMath for uint256;

    address public ckAddress = address(0x0);
    CryptoKittyInterface kittyInterface;

    function Battle(address kCore) public {
        ckAddress = kCore;
        kittyInterface = CryptoKittyInterface(ckAddress);
    }

    /**
     * @dev 
     */
    function doBattle(uint256 _kittyIdAttacker, uint256 _kittyIdDefender)
        external
        view
        isConnected
        returns (uint256)
    {
        uint8 winPercentageAttacker = 10;

        uint[4] memory attackerStats;
        (,,,,, attackerStats[0], attackerStats[1], attackerStats[2], attackerStats[3],) = kittyInterface.getKitty(_kittyIdAttacker);

        uint[4] memory defenderStats;
        (,,,,, defenderStats[0], defenderStats[1], defenderStats[2], defenderStats[3],) = kittyInterface.getKitty(_kittyIdDefender);

        if(attackerStats[0] > defenderStats[0]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[0] == defenderStats[0]) {
            winPercentageAttacker += 10;
        }

        if(attackerStats[1] > defenderStats[1]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[1] == defenderStats[1]) {
            winPercentageAttacker += 10;
        }

        if(attackerStats[2] > defenderStats[2]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[2] == defenderStats[2]) {
            winPercentageAttacker += 10;
        }

        if(attackerStats[3] > defenderStats[3]) {
            winPercentageAttacker += 20;
        }
        else if(attackerStats[3] == defenderStats[3]) {
            winPercentageAttacker += 10;
        }

        bool attackerWins = _randomNumber(0, 100) < winPercentageAttacker;

        if(attackerWins)
            return _kittyIdAttacker;

        return _kittyIdDefender;
    }

    /**
     * @dev Computes a random number based on the psuedorandom blockhash
     */
    function _randomNumber(uint _floor, uint _ceiling)
        internal
        view
        returns (uint)
    {
        require(_ceiling > _floor);
        
        return uint(block.blockhash(block.number-1))%(_ceiling.sub(_floor)).add(_floor);
    }

    modifier isConnected() {
        require(ckAddress != address(0x0));
        _;
    }

}