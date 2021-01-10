var KonukoToken = artifacts.require("KonukoToken");
var SafeMath = artifacts.require("SafeMath");
var BytesLib = artifacts.require("BytesLib");
var ECDSA = artifacts.require("ECDSA");
module.exports = function(_deployer) {
  _deployer.deploy(SafeMath);
  _deployer.deploy(BytesLib);
  _deployer.deploy(ECDSA);
  _deployer.link(SafeMath,KonukoToken);
  _deployer.link(BytesLib,KonukoToken);
  _deployer.link(ECDSA,KonukoToken);
  _deployer.deploy(KonukoToken);
  // Use deployer to state migration tasks.
};

