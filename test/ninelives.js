var BigNumber = require('bignumber.js');

// Specifically request an abstraction for MetaCoin
var NineLives = artifacts.require("NineLives");

contract("NineLives", function(accounts) {
    var nlInstance;
    
    before(async function () {
        nlInstance = await NineLives.deployed();
        
        await nlInstance.spawnKitty(1, {from:accounts[0]});
    });

    describe("Kitty handler", function() {
        it("should spawn kitty", async function() {
            var lives = await nlInstance.getKittyLives(1, {from:accounts[0]});

            assert.equal(lives, 10, "kitty spawn failed");
        });

        it("should fail kitty spawn when already spawned", function() {
            nlInstance.spawnKitty(1, {from:accounts[0]}).then(function() {
                assert(false, "kitty spawn was supposed to revert");
            }).catch(function(error) {
                if(error.toString().indexOf("revert") != -1) {
                    assert(true, "Call reverted. Test succeeded.")
                } else {
                    // if the error is something else (e.g., the assert from previous promise), then we fail the test
                    assert(false, error.toString());
                }
            });
        });

        it("should get kitty info", async function() {
            var kittyInfo = await nlInstance.getKittyInfo(1,{from:accounts[0]});
            assert(kittyInfo[0].equals(10) && !kittyInfo[1], "did not retrieve correct kitty information")
        });
    });

    describe("Payment tests", function() {
        var weiAmount = web3.toWei(0.5, "ether");

        it("should update wei amount", async function() {
            await nlInstance.updateWeiPerSpawn(weiAmount, {from:accounts[0]});
            var weiPerSpawn = await nlInstance.weiPerSpawn({from:accounts[0]});
            assert(weiPerSpawn.equals(weiAmount), "update wei per spawn is broken");
        });

        it("should add refund on overpayment", async function() {
            await nlInstance.spawnKitty(420, {from:accounts[0], value:web3.toWei(1, "ether")});
            var rtn = await nlInstance.pendingReturns(accounts[0], {from:accounts[0]});
            assert(rtn.equals(weiAmount), "return doesn't match expected value");
        });

        it("should send refund ether", async function() {
            var balanceBeforeRefund = await web3.eth.getBalance(NineLives.address);
            await nlInstance.withdrawRefund({from:accounts[0]});
            var balanceAfterRefund = await web3.eth.getBalance(NineLives.address);
            assert(balanceBeforeRefund.minus(weiAmount).equals(balanceAfterRefund), "contract did not refund ether!");
        });

        it("should not send refund ether after withdraw", async function() {
            nlInstance.withdrawRefund({from:accounts[1]}).then(function () {
                assert(false, "contract refunded too much ether!");
            }).catch(function(error) {
                if(error.toString().indexOf("revert") != -1) {
                    assert(true, "Call reverted. Test succeeded.")
                } else {
                    // if the error is something else (e.g., the assert from previous promise), then we fail the test
                    assert(false, error.toString());
                }
            });
        });

        describe("secure functions", function() {
            it("should not be able to update weiPerSpawn", async function() {
                nlInstance.updateWeiPerSpawn(weiAmount, {from:accounts[1]}).then(function () {
                    assert(false, "security is breached");
                }).catch(function(error) {
                    if(error.toString().indexOf("revert") != -1) {
                        assert(true, "Call reverted. Test succeeded.")
                    } else {
                        // if the error is something else (e.g., the assert from previous promise), then we fail the test
                        assert(false, error.toString());
                    }
                });
            });
        });
    });

    describe("Arena functions", function() {
        before(async function() {
            await nlInstance.updateArenaContract(accounts[0], {from:accounts[0]});
        });

        it("should decrement kitty life", function() {
            nlInstance.decrementLives(1, {from:accounts[0]}).then(function() {
                return nlInstance.getKittyLives(1, {from:accounts[0]}); // 8 Lives
            }).then(function(lives) {
                assert.equal(lives, 8, "kitty lives was not decremented!");
            });
        });

        it("shouldn't decerement kitty life below 1", async function() {
            await nlInstance.decrementLives(1, {from:accounts[0]}); // 7
            await nlInstance.decrementLives(1, {from:accounts[0]}); // 6
            await nlInstance.decrementLives(1, {from:accounts[0]}); // 5
            await nlInstance.decrementLives(1, {from:accounts[0]}); // 4
            await nlInstance.decrementLives(1, {from:accounts[0]}); // 3
            await nlInstance.decrementLives(1, {from:accounts[0]}); // 2
            await nlInstance.decrementLives(1, {from:accounts[0]}); // 1
            await nlInstance.decrementLives(1, {from:accounts[0]}); // Should stay 1
            var livesLeft = await nlInstance.getKittyLives(1, {from:accounts[0]});
            assert.equal(livesLeft, 1, "kitty lives decremented is broken!");
        });

        it("should set ready to battle", async function() {
            await nlInstance.setIsReadyToBattle(1, true, {from:accounts[0]});
            var readyToBattle = await nlInstance.isReadyToBattle(1);
            assert(readyToBattle, "ready to battle function broken");
        });

        describe("secure functions", function() {
            before(async function() {
                await nlInstance.updateArenaContract("0x01");
            });

            it("should not be able to decrement lives", async function() {
                await nlInstance.updateArenaContract("0x01");

                nlInstance.decrementLives(1, {from:accounts[0]}).then(function () {
                    assert(false, "security is breached");
                }).catch(function(error) {
                    if(error.toString().indexOf("revert") != -1) {
                        assert(true, "Call reverted. Test succeeded.")
                    } else {
                        // if the error is something else (e.g., the assert from previous promise), then we fail the test
                        assert(false, error.toString());
                    }
                });
            });

            it("should not be able to change kitty readytobattle", async function() {
                nlInstance.setIsReadyToBattle(1, {from:accounts[0]}).then(function () {
                    assert(false, "security is breached");
                }).catch(function(error) {
                    if(error.toString().indexOf("revert") != -1) {
                        assert(true, "Call reverted. Test succeeded.")
                    } else {
                        // if the error is something else (e.g., the assert from previous promise), then we fail the test
                        assert(false, error.toString());
                    }
                });
            });
        });
    });
});