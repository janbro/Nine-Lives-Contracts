let BigNumber = require('bignumber.js');

let Arena = artifacts.require("./Arena.sol");
let KittyCore = artifacts.require("./CryptoKitties/KittyCoreWrapper.sol");
let NineLives = artifacts.require("./NineLives.sol");
let NLToken = artifacts.require("./NLToken.sol");

let logGas = (tx) => {
    logTx && console.info(`
        *******************************
        TX ${tx.receipt.transactionHash} GAS 
        Gas ==> ${tx.receipt.gasUsed}
        *******************************
    `)
    gasUsed += tx.receipt.gasUsed;
}
const separateLogs = () => console.log('\n    ----------------------------------')
const log = (...args) => console.log('\t', ...args);

let gasUsed = 0;
let logTx = false;
let gasLog = false;

contract("Arena", function(accounts) {
    let arenaInstance;
    let kittyCoreInstance;
    let nlInstance;
    let nlTokenInstance;

    beforeEach(() => {
        gasUsed = 0;
    })
    afterEach(() => {
        if(gasLog && gasUsed > 0)
            console.info(`
                *******************************
                TOTAL GAS 
                Gas ==> ${gasUsed}
                *******************************
            `)
    })

    before(async function () {
        arenaInstance = await Arena.deployed();
        kittyCoreInstance = await KittyCore.deployed();
        nlInstance = await NineLives.deployed();
        nlTokenInstance = await NLToken.deployed();

        await kittyCoreInstance.unpause({from:accounts[0]});
        let kcIsPaused = await kittyCoreInstance.paused({from:accounts[0]});

        await nlInstance.unpause({from:accounts[0]});
        let nlIsPaused = await nlInstance.paused({from:accounts[0]});

        await arenaInstance.unpause({from:accounts[0]});
        let arenaIsPaused = await arenaInstance.paused({from:accounts[0]});

        assert(!kcIsPaused && !nlIsPaused && !arenaIsPaused, "Contract couldn't unpause");

        await nlInstance.updateArenaContract(Arena.address);

        await nlInstance.updateCKContract(KittyCore.address);

        await arenaInstance.addTokenAddress(nlTokenInstance.address, {from:accounts[0]});

        // Create the kitties to be used for testing
        for(let i = 1; i <= 10; i++) {
            //Odd kitties go to account[1], even kitties go to account[0]
            await kittyCoreInstance.createPromoKitty(i, accounts[i%2], {from:accounts[0]});
        }

        // Spawn kitties in Nine Lives contract
        for(let i = 1; i <= 10; i++) {
            await nlInstance.spawnKitty(i, {from:accounts[i%2]});
        }
    });

    describe("Kitty handling", function() {
        it("should send kitty ready to battle", async function() {
            // Using kitty 2
            logGas(await kittyCoreInstance.approve(Arena.address, 2, {from:accounts[0]}));
            logGas(await arenaInstance.sendKittyReadyToBattle(2, {from:accounts[0]}));

            let isReadyToBattle = await nlInstance.isReadyToBattle(2, {from:accounts[0]});
            let owner = await kittyCoreInstance.kittyIndexToOwner(2, {from:accounts[0]});

            assert(isReadyToBattle, "Kitty was not set to ready to battle");
            assert(owner == Arena.address, "Kitty was not sent to the arena");
        });

        it("should send kitty back on withdraw", async function() {
            // Using kitty 4
            logGas(await kittyCoreInstance.approve(Arena.address, 4, {from:accounts[0]}));
            logGas(await arenaInstance.sendKittyReadyToBattle(4, {from:accounts[0]}));
            logGas(await arenaInstance.withdrawKitty(4, {from:accounts[0]}));
            let owner = await kittyCoreInstance.kittyIndexToOwner(4, {from:accounts[0]});

            assert(owner == accounts[0], "Kitty was not sent back to owner on withdraw");
        });

        it("should be able to withdraw kitty after battle", async function() {
            // Using kitty 8 and 1
            logGas(await kittyCoreInstance.approve(Arena.address, 8, {from:accounts[0]}));
            logGas(await arenaInstance.sendKittyReadyToBattle(8, {from:accounts[0]}));
            logGas(await kittyCoreInstance.approve(Arena.address, 1, {from:accounts[1]}));
            logGas(await arenaInstance.sendKittyToBattle(1, 8, {from:accounts[1]}));
            logGas(await arenaInstance.withdrawKitty(1, {from:accounts[1]}));
            logGas(await arenaInstance.withdrawKitty(8, {from:accounts[0]}));
            let atkOwner = await kittyCoreInstance.kittyIndexToOwner(1, {from:accounts[1]});
            let defOwner = await kittyCoreInstance.kittyIndexToOwner(8, {from:accounts[0]});

            assert(atkOwner == accounts[1], "Attacking kitty was not sent back to owner");
            assert(defOwner == accounts[0], "Defending kitty was not sent back to owner");
        });

        it("should have decremented kitty life", async function() {
            // Using kitty 8 and 1
            let atkLives = await nlInstance.getKittyLives(1, {from:accounts[1]});
            let defLives = await nlInstance.getKittyLives(8, {from:accounts[0]});

            assert(atkLives != defLives, "Kitty life was not decremented!");
        });

        it("should send dead kitty to graveyard", async function() {
            // Using kitty 3 and 6
            await nlInstance.updateArenaContract(accounts[0], {from:accounts[0]});

            for(let i = 0; i < 8; i++) {
                await nlInstance.decrementLives(3, {from:accounts[0]});
                await nlInstance.decrementLives(6, {from:accounts[0]});
            }

            await nlInstance.updateArenaContract(Arena.address, {from:accounts[0]});

            logGas(await kittyCoreInstance.approve(Arena.address, 6, {from:accounts[0]}));
            logGas(await arenaInstance.sendKittyReadyToBattle(6, {from:accounts[0]}));
            logGas(await kittyCoreInstance.approve(Arena.address, 3, {from:accounts[1]}));
            logGas(await arenaInstance.sendKittyToBattle(3, 6, {from:accounts[1]}));

            let atkOwner = await kittyCoreInstance.kittyIndexToOwner(3, {from:accounts[1]});
            let defOwner = await kittyCoreInstance.kittyIndexToOwner(6, {from:accounts[0]});

            assert(atkOwner == "0x000000000000000000000000000000000000dead" || 
                defOwner == "0x000000000000000000000000000000000000dead", "Kitty wasn't sent to graveyard!");
        });
    });

    describe("Payment handling", function() {
        it("should receive NLToken as reward", async function() {
            let accBal = await nlTokenInstance.balanceOf(accounts[1], {from:accounts[0]});
            logGas(await arenaInstance.withdrawRewards({from:accounts[1]}));
            let accBalAfter = await nlTokenInstance.balanceOf(accounts[1], {from:accounts[0]});
            
            assert(accBalAfter > accBal, "NLToken reward wasn't payed out");
        });
    });

});