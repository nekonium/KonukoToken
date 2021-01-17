var KonukoToken = artifacts.require("KonukoToken");
module.exports = function(_deployer) {
  _deployer.deploy(KonukoToken);
};

