var NineLives = artifacts.require("./NineLives.sol");
var Arena = artifacts.require("./Arena.sol");
var Battle = artifacts.require("./Battle.sol");

module.exports = function(deployer) {
  deployer.deploy(NineLives).then(()=>{
    return deployer.deploy(Battle).then(()=>{
      return deployer.deploy(Arena, NineLives.address, Battle.address);
    });
  });
};
