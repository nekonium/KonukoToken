const truffleAssert = require("truffle-assertions");
const TestKonukoToken = artifacts.require("KonukoToken");
var BN = web3.utils.BN;

const SIGNED_ACCOUNTS=[
  "0x4B647402e73185AE03b5591B43F5236eCcfcff23",
  "0xe9b2857fd2500157122924efa5045a118d797a77"];

const SNAPSHOT_ACCOUNTS=[
  [
    "0x235D224264D23a9B15385eBBFD665f49D5519Aec",
    new BN("3518437500000000000000"),
    "0x235d224264d23a9b15385ebbfd665f49d5519aec00002710000000bebc2108c4e973c00054455354000000000000000000000000415f0c29702649a76c10f1daaa9008a5f78820e92d99e99d02e62d0881a1449345a467ffc1e2d9482e53cf7378fa824ce274222ea13b990ed18f053f154d77481b55ef4c6e0a9973ca57721ec6e343204076aaa692e06609894ff31cfcf21ef4072115900e81728beaea06fcc9aff1ed8c8535e7ccdca2ca36b2518cb5756697621c"
  ],
  [
    "0x51A6531E3215b00Cff6c166644117372DB585c48",
    new BN("7500000000000000000"),
    "0x51a6531e3215b00cff6c166644117372db585c48000027100000000068155a43676e0000544553540000000000000000000000000f711692978b61d103c4a5b0a5e758dfcb91fb9ba3feb20fc60b5b45e61d265245b2389efab2dc3fc85180f2bd97449740f2c114ec79b4073361b6ce72e485bc1b81ce8af364ab9d7ff7c53d07ec5bb726ddf577a2791616b2a9e7988b0411763433e92e066779e0c01ab97c67a9a8801c4ccc813debfb8f1a5300153ada66fbdb1c"
  ]
];
const CALLER_PROFIT=new BN("29900000000000000000");
/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("KonukoToken", function (accounts) {
  /**
   * accountのbalanceとsnapshotをチェックする
   */
  async function assertAccount(token,account_,balance_,snapshot_){
    let s=await token.snapshotOf(account_);
    let b=await token.balanceOf(account_);
    assert.equal(new BN(snapshot_).cmp(s),0,"snapshot:"+s+"is not equal"+snapshot_);
    assert.equal(new BN(balance_).cmp(b),0,"balance:"+b+"is not equal"+balance_);
  }
  async function assertToken(token,total_supply_){
    let ts=await token.totalSupply();
    assert.equal(new BN(total_supply_).cmp(ts),0,"total_supply:"+ts+"is not equal"+total_supply_);
  }



  it("should assert true", async () => {
    await TestKonukoToken.new();
    return assert.isTrue(true);
  });
  //
  // hasSnapshot
  //
  //存在しないアカウントでhasSnapshotが失敗する事
  it("hasSnapshot must be false if undefined account.", async () =>
  {
    let token=await TestKonukoToken.new();
    let b=await token.hasSnapshot(SNAPSHOT_ACCOUNTS[0][0], {from:accounts[0]});
    assert.equal(b,false,"hasSnapshot failed");
    return true;
  });
  //登録後にはhasSnapshotがtrueになること
  it("hasSnapshot must be true if account exist.",async () =>
  {
    let token=await TestKonukoToken.new();
    let r1=await token.makeSnapshot(SNAPSHOT_ACCOUNTS[0][2], {from:accounts[0]});
    let r2=await token.hasSnapshot(SNAPSHOT_ACCOUNTS[0][0], {from:accounts[0]});
    assert.equal(r2,true,"hasSnapshot failed");
    return true;
  });
  //登録後(1回)にbalance,snapshot,totalSupplyが正しい値で遷移する事
  it("makeSnapshot must set correct parameters(one account).",  async () =>
  {
    let token=await TestKonukoToken.new();
    let r2=await token.hasSnapshot(SNAPSHOT_ACCOUNTS[0][0], {from:accounts[0]});
    assert.equal(r2,false,"hasSnapshot failed");

    { //before check
      await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],0,0);
      await assertAccount(token,accounts[0],0,0);
      await assertToken(token,0);
    }
    let r1=await token.makeSnapshot(SNAPSHOT_ACCOUNTS[0][2], {from:accounts[0]});
    { //after check
      await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],SNAPSHOT_ACCOUNTS[0][1],SNAPSHOT_ACCOUNTS[0][1]);
      await assertAccount(token,accounts[0],CALLER_PROFIT,0);
      await assertToken(token,SNAPSHOT_ACCOUNTS[0][1].add(CALLER_PROFIT));
    }
    return true;
  });
  //異なるアカウントにmakeSnapshotした場合にもそれぞれのbalance,snapshot,totalSupplyが正しい値であること
  it("makeSnapshot must set correct parameters(two account).", async () =>
  {
    let token=await TestKonukoToken.new();
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],0,0);
    await assertAccount(token,SNAPSHOT_ACCOUNTS[1][0],0,0);
    await assertAccount(token,accounts[0],0,0);
    await assertToken(token,0);

    await token.makeSnapshot(SNAPSHOT_ACCOUNTS[0][2], {from:accounts[0]});
    await token.makeSnapshot(SNAPSHOT_ACCOUNTS[1][2], {from:accounts[0]});
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],SNAPSHOT_ACCOUNTS[0][1],SNAPSHOT_ACCOUNTS[0][1]);
    await assertAccount(token,SNAPSHOT_ACCOUNTS[1][0],SNAPSHOT_ACCOUNTS[1][1],SNAPSHOT_ACCOUNTS[1][1]);
    await assertAccount(token,accounts[0],CALLER_PROFIT.mul(new BN(2)),0);
    await assertToken(token,SNAPSHOT_ACCOUNTS[0][1].add(SNAPSHOT_ACCOUNTS[1][1]).add(CALLER_PROFIT.mul(new BN(2))));
    return true;
  });


  //誤ったトランザクションを受け付けないこと。また、実行後に残高が変更されない事。
  it("makeSnapshot must not accect invalid transaction(4).", async () =>
  {
    let token=await TestKonukoToken.new();
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],0,0);
    await assertAccount(token,accounts[0],0,0);
    await assertToken(token,0);

    let d;
    d=SNAPSHOT_ACCOUNTS[0][2].substring(0,123);
    await truffleAssert.reverts(token.makeSnapshot(d, {from:accounts[0]}),"Invalid tx length");
    d="0x235d224264d23a9b15385ebbfd665f49d5519aec0000271000000000000000000000000054455354000000000000000000000000415f0c29702649a76c10f1daaa9008a5f78820e92d99e99d02e62d0881a1449345a467ffc1e2d9482e53cf7378fa824ce274222ea13b990ed18f053f154d77481b55ef4c6e0a9973ca57721ec6e343204076aaa692e06609894ff31cfcf21ef4072115900e81728beaea06fcc9aff1ed8c8535e7ccdca2ca36b2518cb5756697621c";
    await truffleAssert.reverts(token.makeSnapshot(d, {from:accounts[0]}),"No snapshot amount");
    d="0x235d224264d23a9b15385ebbfd665f49d5519aec000027f0000000bebc2108c4e973c00054455354000000000000000000000000415f0c29702649a76c10f1daaa9008a5f78820e92d99e99d02e62d0881a1449345a467ffc1e2d9482e53cf7378fa824ce274222ea13b990ed18f053f154d77481b55ef4c6e0a9973ca57721ec6e343204076aaa692e06609894ff31cfcf21ef4072115900e81728beaea06fcc9aff1ed8c8535e7ccdca2ca36b2518cb5756697621c";
    await truffleAssert.reverts(token.makeSnapshot(d, {from:accounts[0]}),"Invalid block height field");
    d="0x235d224264d23a9b15385ebbfd665f49d5519aec00002710000000bebc2108c4e973c0005445535DEAD000000000000000000000415f0c29702649a76c10f1daaa9008a5f78820e92d99e99d02e62d0881a1449345a467ffc1e2d9482e53cf7378fa824ce274222ea13b990ed18f053f154d77481b55ef4c6e0a9973ca57721ec6e343204076aaa692e06609894ff31cfcf21ef4072115900e81728beaea06fcc9aff1ed8c8535e7ccdca2ca36b2518cb5756697621c";
    await truffleAssert.reverts(token.makeSnapshot(d, {from:accounts[0]}),"Invalid MESSAGE field");
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],0,0);
    await assertAccount(token,accounts[0],0,0);
    await assertToken(token,0);
    return true;
  });

  //登録済みのアドレスに登録できない事
  it("makeSnapshot must not accept when already exist parameters(3).", async () =>
  {
    let token=await TestKonukoToken.new();
    await token.makeSnapshot(SNAPSHOT_ACCOUNTS[0][2], {from:accounts[0]});
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],SNAPSHOT_ACCOUNTS[0][1],SNAPSHOT_ACCOUNTS[0][1]);
    await assertAccount(token,accounts[0],CALLER_PROFIT,0);
    await assertToken(token,SNAPSHOT_ACCOUNTS[0][1].add(CALLER_PROFIT));
    await truffleAssert.reverts(token.makeSnapshot(SNAPSHOT_ACCOUNTS[0][2], {from:accounts[0]}),"Snapshot Already exists");
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],SNAPSHOT_ACCOUNTS[0][1],SNAPSHOT_ACCOUNTS[0][1]);
    await assertAccount(token,accounts[0],CALLER_PROFIT,0);
    await assertToken(token,SNAPSHOT_ACCOUNTS[0][1].add(CALLER_PROFIT));
    return true;
  });
  //BURNアドレスに残高を生成できないこと
  it("makeSnapshot must not make balance and snapshot to BURN address.", async () =>
  {
    let token=await TestKonukoToken.new();
    await truffleAssert.reverts(token.makeSnapshot("0xbc4517bc2dde774781e3d7b49677de3449d4d581000027100001a784379d99db420000005445535400000000000000000000000075ac574120447c92368453036e80a5b5f812d79e442f438dd877fd3269cd5a012d8645bf4ed83590baba9a2271dcadaf5e3197f67d167e3aa092f68e86cc899b1c37b530ceecc8fc425253ce5593eef7df37e4c9789918d4def6d1f08890579fe94154cceaabbf6b6df8cd8845d68bf65fe5bdbc76899d7ccd3bcaee3cbf057d8a1c", {from:accounts[0]}),"BURN target");
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],0,0);
    await assertAccount(token,accounts[0],0,0);
    await assertToken(token,0);
    return true;
  });

  //バランスが転送された後に、二つのアドレスの残高が正しく遷移していること
  it("transfer must set balances correctly.", async () =>
  {
    //a[0]からA[0]
    let token=await TestKonukoToken.new();
    //SNAPSHOTを生成
    await token.makeSnapshot(SNAPSHOT_ACCOUNTS[0][2], {from:accounts[0]});
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],SNAPSHOT_ACCOUNTS[0][1],SNAPSHOT_ACCOUNTS[0][1]);
    await assertAccount(token,accounts[0],CALLER_PROFIT,0);
    await assertToken(token,SNAPSHOT_ACCOUNTS[0][1].add(CALLER_PROFIT));
    //送信 
    token.transfer(SNAPSHOT_ACCOUNTS[0][0],1000,{from:accounts[0]});
    token.transfer("0x0000000000000000000000000000000000000002",2000,{from:accounts[0]});
    await assertAccount(token,accounts[0],CALLER_PROFIT.sub(new BN(1000+2000)),0);
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],SNAPSHOT_ACCOUNTS[0][1].add(new BN(1000)),SNAPSHOT_ACCOUNTS[0][1]);
    await assertAccount(token,"0x0000000000000000000000000000000000000002",2000,0);
    await assertToken(token,SNAPSHOT_ACCOUNTS[0][1].add(CALLER_PROFIT));
  });
  //バランスが不足したときに、二つのアドレスの残高が変化しない事
  it("transfer must not transfer when insufficient balancre (3).", async () =>
  {
    let token=await TestKonukoToken.new();
    await token.makeSnapshot(SNAPSHOT_ACCOUNTS[0][2], {from:accounts[0]});
    await truffleAssert.reverts(token.transfer(SNAPSHOT_ACCOUNTS[0][0],CALLER_PROFIT.mul(new BN(2)),{from:accounts[0]}));
    await assertAccount(token,SNAPSHOT_ACCOUNTS[0][0],SNAPSHOT_ACCOUNTS[0][1],SNAPSHOT_ACCOUNTS[0][1]);
    await assertAccount(token,accounts[0],CALLER_PROFIT,0);
    await assertToken(token,SNAPSHOT_ACCOUNTS[0][1].add(CALLER_PROFIT));
    return true;
  });

  //自己生成の場合、自身のアドレスに報酬が加算されていること。
});



