# KonukoToken

このコントラクトは、Nekoniumのクロスチェーンハードフォークに使うトークンコントラクトです。

Nekoniumチェーンから生成したマルチシグ残高証明トランザクションを元に、対象ネットワークへ残高を記録し、同量のトークンを生成します。
チェーンにとってはハードフォークですが、ユーザーにとっては申告を要するトークンエアドロップに近い意味を持ちます。

対象ネットワークはEthereum mainnetを想定していますが、Ethereumと互換性のあるアドレスであれば、応用することが可能です。

## 特徴
※トークンに価値は保障されませんが、ここでは受け取るトークンを報酬として表現します。

 - 生成するトークンはERC223トークンと互換性があります。
 - ERC223のbalance値とは別に、アカウントのスナップショット残高を示すsnapshot値があります。
 - スナップショット残高の記録とトークン生成の為に、２つの拡張関数があります。
 - totalSupplyは、残高スナップショットの合計値＋残高スナップショットの数量×書き込み報酬です。
 - マルチシグを用いることで、単独の署名者による不正な残高証明の発行を防止します。
 - アップデート・プロキシ機能、事後調整機能を持ちません。不具合やハッキングに対して無防備です。


このトークンの目的は、Nekoniumの残高スナップショットを流動性を維持したまま他のチェーンへ保管することです。
何らかの資金調達や、将来的な付加価値を約束するものではありません。投機・投資・貯蓄活動の為の利用はご遠慮ください。


## コントラクトを取り巻く登場者
※トークンに価値は保障されませんが、ここでは受け取るトークンを報酬として表現します。

コントラクトを取り巻く登場者を紹介します。

- トークン生成者（残高生成者）
- 署名者
- 登録者
- 残高所有者

トークン生成者は、このコントラクトの可変パラメータを決定し、対象ネットワークにデプロイし、そこに生成する残高証明のリストを作成します。

署名者は、トークン生成者が生成した残高リストの正統性に、そのアカウントで署名を行います。

登録者は、署名者が署名済みの残高証明をコントラクトに送信し、対象ネットワークに残高情報とトークン残高を発生させます。

残高所有者は、Nekoniumネットワークの、あるブロック高について、残高を持つアカウントの所有者です。

### 報酬とコスト

トークン生成者はコントラクトのパラメータを決定できます。デプロイの為に対象ネットワークに手数料を支払いますが、直接得られる報酬はありません。

署名者の収受する手数料や報酬はありません。

登録者はトランザクション送信の為に対象ネットワークに手数料を支払います。その代わり、登録に成功した場合は固定値のトークン残高を得ます。

残高所有者が登録者と同一な場合は、残高所有者はトランザクション送信の為に対象ネットワークに手数料を支払い、登録に成功した場合は固定値のトークン残高と残高証明にある額の合計を受け取ります。残高所有者が登録者と異なる場合は、他の登録者が登録に成功した場合に、残高証明にあるトークン残高を受け取ります。

### 残高証明の正当性について

残高は、トークン生成者によって生成します。これを署名者が検証して署名することで、残高証明を正統化します。

署名者が多いほど、後に不正な残高生成をすることが難しくなります。署名するアカウントは、それぞれの信頼性をアカウントの所属するネットワークで担保します。
署名者は様々な立場で複数人が参加するべきです。これにより、事後の談合による不正な署名が防止されます。アカウントではなく、アカウントの所有者で正統性を担保するならば、一次的に生成したアカウントを署名に使用し、署名後に検証不能な形で破棄する方式も使用できます。

### トークンの取得機会

残高証明を持つ残高所有者は、自身が登録者になるか、または他社によって自分のトランザクションが送信されることで、トークンを得ます。
残高証明を持たない登録者は、トランザクションの送信により、対象ネットワークへの手数料と引き換えにトークンを得る機会を得ます。


## コントラクトの設置方法

### パラメータの決定
トークンをデプロイする前に、次のパラメータを決定します。これらのパラメータは、コントラクトのソースにハードコートします。

1. スナップショットを実施するNekoniumチェーンのブロック高。
2. トークン発行の対象から外すアカウントリスト。
3. 書き込みリワードの数量。
4. HF識別子となる16文字の識別子


1のブロック高は、過去でも未来でも構いません。スナップショットを製造するためにはNekoniumチェーンのブロック高がその値を超える必要があります。
2のアカウントリストは、運用又は政治的な理由で除外したいアカウントを対象にします。Nekoniumチェーンのプレマインアカウントや、BURNアカウントのリストを指定するべきです。
3の書き込みリワードは、コントラクトの実行者が受け取るトークンの数量を指定します。アカウント数×数量が、残高証明とは別に発行されることに注意してください。
4の識別子はユーザー領域です。お好みの文字列を設定します。16文字に満たない部分は0パディングして下さい。

### テスト
ganache-cliを起動しておきます。
```
$ganache-cli
```
truffleでテストします。
```
$truffle test --network ganache
```
全部パスするならきっと大丈夫。


### トークンのデプロイ
ソースファイルをコンパイルしてデプロイします。

gethでアカウントをアンロックします。
```
>web3.personal.unlockAccount(web3.eth.accounts[0])
```
プライベートネットワークの場合はマイニングを開始しておきます。
```
>miner.start(1)
```

truffle-config.jsのgethの設定を書き換えます。
fromにweb3.eth.accounts[0]のアカウントを設定してください。
```
    geth: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",         // Any network (default: none)
      from :"0x256e5d036d544aaf0ea467cebea60ad00e41d943",
      gas: 4700000,           // Gas sent with each transaction (default: ~6700000)
    },
```
デプロイします。**アカウントの残高が消費されるのでメインネットにつながってるgethで実行しないでください。**
```
$truffle migrate --network geth

Compiling your contracts...
===========================
> Everything is up to date, there is nothing to compile.
:
:
   > transaction hash:    0xd65e63a00d42013b57ff083a7cc4820f467501959afd27345f6a5b34f7c892cc
   > Blocks: 1            Seconds: 36
   > contract address:    0xCd8DC2e6ED0a638bF722F71eEbA953d6743955bd
   > block number:        2
   > block timestamp:     1610868621
   > account:             0x256e5D036d544AAf0ea467cEbEA60ad00e41D943
   > balance:             904625697166532776746648320380374280103671755200316906558.262375061821325312
   > gas used:            2165624 (0x210b78)
   > gas price:           20 gwei
   > value sent:          0 ETH
   > total cost:          0.04331248 ETH
:
:
Summary
=======
> Total deployments:   1
> Final cost:          0.04331248 ETH
```
コントラクトがデプロイできれば成功です。

### マルチシグ残高証明トランザクションの生成

残高生成の元とするマルチシグ残高証明トランザクションをNukoPunchで生成します。

まずはgnekoniumを同期してフルノードを構築します。
```
$ gnekonium --rpc --rpcaddr "localhost" --syncmode full console
```

blockScan.pyでチェーンに存在するアカウント情報を全て取得します。
```
$python3 blockScan.py 0 --format sqlite --out ./nekonium_accounts.sqlite3
```

スナップショット残高を生成します。ここではブロック高100000を指定しました。
```
$python3 balanceSnapshot.py ./nekonium_accounts.sqlite3 100000 --format sqlite
```

スナップショット残高をJSONへ書き出します。messageの値はTEST\0\0\0\0\0\0\0\0\0\0\0\0とします。
```
$python3 genSignedBalanceList.py init nekonium_accounts.sqlite3 100000 --message TEST --out ./signed.json
```

スナップショットに署名します。BURNリストへ指定した順番で署名をしてください。
```
$python3 genSignedBalanceList.py sign ./signed.json 0x4b647402e73185ae03b5591b43f5236eccfcff23 --password "PASSWORD"
```
全ての署名が終わったら、JSON、またはCSVへトランザクションリストを書き出します。ここではCSVを選択します。
```
$python3 genSignedBalanceList.py export --format csv ./signed.json
```

次のようなCSVが出力されます。適切に加工して、Webサイトなどの残高所有者全員が閲覧可能な場所にアップロードしてください。
```
version	created_date
SignedBalanceList/0.1;BalanceCertification/0.1	2020-12-24 21:24:15.853105
:
0x0000000000000000000000000000000000000000	0.0	0	0x000000000000000000000000000000000000000000002710000000000000000000000000544553540000000000000000000000002076a645a9703d01a9d01beae5a0f7940db453653d313945fe4944704b6c9b334db3206213b9e9f66133309b824885e84485084732bae2b826c34b50f97b2c761c
0xdcEa28Ea2Cb699bF020a6D4738EB3A94D9FAEBb7	26088.920726	26088920726000000000000	0xdcea28ea2cb699bf020a6d4738eb3a94d9faebb70000271000000586488187455c176000544553540000000000000000000000004884f34ceb81d7ff230e91ff7c3bbf9934932a71a1122de48339ed97b333343d3740ecb17b7e23779b3ab3afed5ba59702d3495513e78cd11942dfb919d4b02e1c
:
```

### トークンの取得

ABIを生成します。
```
solc --abi contracts/KonukoToken.sol -o abis
```
gethでコントラクトにバインドしたabiを生成します。
atの引数はコントラクトをデプロイしたアドレスを指定します。
```
abi=[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_caller","type":"address"},{"indexed":false,"internalType":"uint128","name":"_caller_reword","type":"uint128"},{"indexed":true,"internalType":"address","name":"_account","type":"address"},{"indexed":false,"internalType":"uint128","name":"_snapshot","type":"uint128"}],"name":"MakeSnapshot","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_from","type":"address"},{"indexed":true,"internalType":"address","name":"_to","type":"address"},{"indexed":false,"internalType":"uint256","name":"_value","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"_data","type":"bytes"}],"name":"Transfer","type":"event"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"BURN_ADDRS","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"CALLER_PROFIT","outputs":[{"internalType":"uint128","name":"","type":"uint128"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"FORK_HEIGHT","outputs":[{"internalType":"uint32","name":"","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"PROOF_ADDRS","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"SIGN_MESSAGE","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"balance","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_target","type":"address"}],"name":"hasSnapshot","outputs":[{"internalType":"bool","name":"_hasSnapshot","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"_tx","type":"bytes"}],"name":"makeSnapshot","outputs":[{"internalType":"int256","name":"success","type":"int256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_owner","type":"address"}],"name":"snapshotOf","outputs":[{"internalType":"uint256","name":"snapshot","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"success","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_value","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"transfer","outputs":[{"internalType":"bool","name":"success","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]
contract = web3.eth.contract(abi).at("0xCd8DC2e6ED0a638bF722F71eEbA953d6743955bd");
```


後で書く

