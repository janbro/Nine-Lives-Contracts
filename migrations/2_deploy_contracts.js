var NineLives = artifacts.require("./NineLives.sol");
var Arena = artifacts.require("./Arena.sol");
var Battle = artifacts.require("./Battle.sol");
var KittyCore = artifacts.require("./CryptoKitties/KittyCore.sol");

module.exports = function(deployer) {
  deployer.deploy(NineLives).then(function() {
    return deployer.deploy(KittyCore).then(function() {
      return deployer.deploy(Battle, KittyCore.address).then(function() {
        return deployer.deploy(Arena, NineLives.address, Battle.address, KittyCore.address);
      });
    });
  });
};
