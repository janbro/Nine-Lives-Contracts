var NineLives = artifacts.require("./NineLives.sol");
var Arena = artifacts.require("./Arena.sol");
var Battle = artifacts.require("./Battle.sol");
var NLToken = artifacts.require("./NLToken.sol");
var KittyCoreWrapper = artifacts.require("./CryptoKitties/KittyCoreWrapper.sol");

module.exports = function(deployer) {
  deployer.deploy(NineLives, 0).then(function() {
    return deployer.deploy(KittyCoreWrapper).then(function() {
      return deployer.deploy(Battle, KittyCoreWrapper.address).then(function() {
        return deployer.deploy(Arena, NineLives.address, Battle.address, KittyCoreWrapper.address).then(function() {
          return deployer.deploy(NLToken, Arena.address);
        });
      });
    });
  });
};
