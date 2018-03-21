var BigNumber = require('bignumber.js');

var Arena = artifacts.require("./Arena.sol");
var KittyCore = artifacts.require("./CryptoKitties/KittyCore.sol");
var NineLives = artifacts.require("./NineLives.sol");
var NLToken = artifacts.require("./NLToken.sol");

contract("Arena", function(accounts) {
    var arenaInstance;
    var kittyCoreInstance;
    var nlInstance;
    var nlTokenInstance;

    before(async function () {
        arenaInstance = await Arena.deployed();
        kittyCoreInstance = await KittyCore.deployed();
        nlInstance = await NineLives.deployed();
        nlTokenInstance = await NLToken.deployed();

        await kittyCoreInstance.unpause({from:accounts[0]});
        var kcIsPaused = await kittyCoreInstance.paused({from:accounts[0]});

        await nlInstance.unpause({from:accounts[0]});
        var nlIsPaused = await nlInstance.paused({from:accounts[0]});

        await arenaInstance.unpause({from:accounts[0]});
        var arenaIsPaused = await arenaInstance.paused({from:accounts[0]});

        assert(!kcIsPaused && !nlIsPaused && !arenaIsPaused, "Contract couldn't unpause");

        await nlInstance.updateArenaContract(Arena.address);

        await arenaInstance.addTokenAddress(nlTokenInstance.address, {from:accounts[0]});

        for(var i = 0; i < 10; i++) {
            //Odd kitties go to account[0], even kitties go to account[1]
            await kittyCoreInstance.createPromoKitty(i, accounts[i%2], {from:accounts[0]});
        }
        
        for(var i = 1; i <= 10; i++) {
            await nlInstance.spawnKitty(i, {from:accounts[i%2]});
        }
    });

    describe("Kitty handling", function() {
        it("should send kitty ready to battle", async function() {
            await kittyCoreInstance.approve(Arena.address, 2, {from:accounts[1]});
            await arenaInstance.sendKittyReadyToBattle(2, {from:accounts[1]});
            var isReadyToBattle = await nlInstance.isReadyToBattle(2, {from:accounts[1]});
            var owner = await kittyCoreInstance.kittyIndexToOwner(2, {from:accounts[1]});

            assert(isReadyToBattle, "Kitty was not set to ready to battle");
            assert(owner == Arena.address, "Kitty was not sent to the arena");
        });

        it("should send kitty back on withdraw", async function() {
            await kittyCoreInstance.approve(Arena.address, 4, {from:accounts[1]});
            await arenaInstance.sendKittyReadyToBattle(4, {from:accounts[1]});
            await arenaInstance.withdrawKitty(4, {from:accounts[1]});
            var owner = await kittyCoreInstance.kittyIndexToOwner(4, {from:accounts[1]});

            assert(owner == accounts[1], "Kitty was not sent back to owner on withdraw");
        });

        it("should be able to withdraw kitty after battle", async function() {
            await kittyCoreInstance.approve(Arena.address, 8, {from:accounts[1]});
            await arenaInstance.sendKittyReadyToBattle(8, {from:accounts[1]});
            await kittyCoreInstance.approve(Arena.address, 1, {from:accounts[0]});
            await arenaInstance.sendKittyToBattle(1, 8, {from:accounts[0]});
            await arenaInstance.withdrawKitty(1, {from:accounts[0]});
            await arenaInstance.withdrawKitty(8, {from:accounts[1]});
            var atkOwner = await kittyCoreInstance.kittyIndexToOwner(1, {from:accounts[0]});
            var defOwner = await kittyCoreInstance.kittyIndexToOwner(8, {from:accounts[1]});

            assert(atkOwner == accounts[0], "Attacking kitty was not sent back to owner");
            assert(defOwner == accounts[1], "Defending kitty was not sent back to owner");
        });

        it("should have decremented kitty life", async function() {
            var atkLives = await nlInstance.getKittyLives(1, {from:accounts[0]});
            var defLives = await nlInstance.getKittyLives(8, {from:accounts[1]});

            assert(atkLives != defLives, "Kitty life was not decremented!");
        });

        it("should send dead kitty to graveyard", async function() {
            await nlInstance.updateArenaContract(accounts[0], {from:accounts[0]});

            for(var i = 0; i < 8; i++) {
                await nlInstance.decrementLives(3, {from:accounts[0]});
                await nlInstance.decrementLives(6, {from:accounts[0]});
            }

            await nlInstance.updateArenaContract(Arena.address, {from:accounts[0]});

            await kittyCoreInstance.approve(Arena.address, 6, {from:accounts[1]});
            await arenaInstance.sendKittyReadyToBattle(6, {from:accounts[1]});
            await kittyCoreInstance.approve(Arena.address, 3, {from:accounts[0]});
            await arenaInstance.sendKittyToBattle(3, 6, {from:accounts[0]});

            var atkOwner = await kittyCoreInstance.kittyIndexToOwner(3, {from:accounts[0]});
            var defOwner = await kittyCoreInstance.kittyIndexToOwner(6, {from:accounts[1]});

            assert(atkOwner == "0x000000000000000000000000000000000000dead" || 
                defOwner == "0x000000000000000000000000000000000000dead", "Kitty wasn't sent to graveyard!");
        });
    });

    describe("Payment handling", function() {
        it("should receive NLToken as reward", async function() {
            var accBal = await nlTokenInstance.balanceOf(accounts[0], {from:accounts[0]});
            await arenaInstance.withdrawRewards({from:accounts[0]});
            var accBalAfter = await nlTokenInstance.balanceOf(accounts[0], {from:accounts[0]});
            assert(accBalAfter > accBal, "NLToken reward wasn't payed out");
        });
    });

});