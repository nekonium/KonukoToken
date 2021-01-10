const TestKonukoToken = artifacts.require("KonukoToken");


const SIGNED_ACCOUNTS=[
  "0x4b647402e73185ae03b5591b43f5236eccfcff23",
  "0xe9b2857fd2500157122924efa5045a118d797a77"];

const ACCOUNT1="0x4b647402e73185ae03b5591b43f5236eccfcff23"
/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("KonukoToken", function (/* accounts */) {
  it("should assert true", async function () {
    await TestKonukoToken.deployed();
    return assert.isTrue(true);
  });

  it("hasSnapshot test", function()
  {
    var token;
    return TestKonukoToken.deployed().then(function(instance) {
      token = instance;
      return token.hasSnapshot(ACCOUNT1, {from: ACCOUNT1});
    }).then(function(message) {
      return assert.equal(message,false,"hasSnapshot failed");
    });
  });
});



