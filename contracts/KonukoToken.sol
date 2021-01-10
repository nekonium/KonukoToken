pragma solidity >=0.7.3 <0.8.0;
// SPDX-License-Identifier: MIT
/**
 * KONUKO-token
 * このコントラクトは、クロスチェーンハードフォークを目的とするトークンコントラクトです。
 * ERC223トークンと互換性があります。
 * 別に用意した残高証明トランザクションをチェーンへ書き込み、同額の残高をそのアカウントへ生成します。
 * 関数を実行したアカウントは、残高証明の値とは別に、固定の報酬として既定のトークンを取得できます。
 * 
 * 
 * ERC223に追加して実装される関数は以下の通りです。
 * makeSnapshot
 * 残高トランザクションを登録し、スナップショットをチェーンに記録してトークン残高を生成します。
 * hasSnapshot
 * アカウントのスナップショットがチェーンに記録されているかを調べます。
 * 
 */

 
//https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol
library SafeMath {
    uint256 constant public MAX_UINT256 =0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z)
    {
        if (x > MAX_UINT256 - y){
            revert();
        }
        return x + y;
    }
    
    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z)
    {
        if (x < y){
            revert();
        }
        return x - y;
    }
    
    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z)
    {
        if (y == 0){
            return 0;
        }
        if (x > MAX_UINT256 / y){
            revert();
        }
        return x * y;
    }
}

//https://github.com/GNSPS/solidity-bytes-utils
library BytesLib{
    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32)
    {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }
    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64)
    {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }
        return tempUint;
    }
    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96)
    {
        require(_start + 12 >= _start, "toUint96_overflow");
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }
    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128)
    {
        require(_start + 16 >= _start, "toUint128_overflow");
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }
    function slice(bytes memory _bytes,uint256 _start,uint256 _length) internal pure returns (bytes memory){
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }    
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address)
    {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }
    /**
     * https://ethereum.stackexchange.com/questions/884/how-to-convert-an-address-to-bytes-in-solidity
     */
    function toBytes(address a) public pure returns (bytes memory b){
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
       }
    }
    function bytesEquals(bytes calldata a,bytes calldata b) public pure returns(bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

/*
 * https://gist.github.com/BjornvdLaan/e41d292339bbdebb831d0b976e1804e8 
 */
library ECDSA
{
    /**
    * @dev Recover signer address from a message by using their signature
    * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
    * @param signature bytes signature, the signature is generated using web3.eth.sign()
    */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }
        
        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
    function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}





abstract contract ContractReceiver
{
    function tokenFallback(address _from, uint _value, bytes calldata _data) external virtual ;
}




contract KonukoToken
{
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    
    mapping(address => uint128) private snapshot;//スナップショットの値
    mapping(address => uint256) private balances;//トークンの残高
    
    
    string public name    = "NekoniumForkToken.R3";
    string public symbol  = "KONUKO";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    


    constructor() 
    {
        //Supply of 100 tokens with 18 decimals. (100 + 18 times zero)
        totalSupply = 0;
    }


    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes calldata _data) public returns (bool success){
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success){
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty="\x00";
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }else{
            return transferToAddress(_to, _value, empty);
        }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract){
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool success)
    {
        if (balanceOf(msg.sender) < _value){
            revert();
        }
        balances[msg.sender] = SafeMath.safeSub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool success)
    {
        if (balanceOf(msg.sender) < _value){
            revert();
        }
        balances[msg.sender] = SafeMath.safeSub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    
    function balanceOf(address _owner) public view  returns (uint balance)
    {
        return balances[_owner];
    }

    
    address[2] public PROOF_ADDRS=[
        0xBbFdCBbD22960B6fcf4a0a101b816614aa551c4b,
        0xBbFdCBbD22960B6fcf4a0a101b816614aa551c4b
    ];
    bytes public constant SIGN_MESSAGE = "NekoniumFork/001"; //MUST BE 16 bytes!
    uint32 public constant FORK_HEIGHT=0;
    uint public constant CALLER_PROFIT=299*100000000000000000;
    address[] public BURN_ADDRS=[
        0xBbFdCBbD22960B6fcf4a0a101b816614aa551c4b,
        0xBc4517bc2ddE774781E3D7B49677DE3449D4D581,
        0x62A87d9716b5826063d98294688ec76F774034d6,
        0x817570E7E0838ca0c6c136bF9701962FF7a6e562,
        0xbd2746c132393fD822D971EecAF7f4cd770A5472        
    ];        
    /**
     * スナップショットが書き込み済みかを返す.
     * snapshotmapが0以外の場合に値が書き込まれていると判定します。
     */
    function hasSnapshot(address _target) public view returns (bool _hasSnapshot)
    {
        if(snapshot[_target]>0){
            return true;
        }
        return false;
    }

    /**
     * スナップショットを書き込みます。
     * 書き込んだアカウントと、書き込みに成功したアカウントに残高を与えます。です。
     * 
     * 次の条件をすべて満たすときに、コントラクトをコールしたアカウントとパラメータにあるアカウントへ残高を付与します。
     * 付与量は、コントラクトをコールしたアカウントにCALLER_PROFIT、パラメータにあるアカウントにamountです。
     * 
     * - _tx[address]がsnapshotに存在しない事。
     * - amountが0より大きいこと。
     * - heightとmessageがコントラクトの定義値と等しいこと。
     * - _tx[address]がBURN_ADDRSに含まれていない事。
     * - _tx[sign]がそれぞれのPROOF_ADDRSによって署名されていること
     * 
     * 
     * @param _tx byte[52+n*64]
     * [address][amount][height][message]
     * address as bytes20 バランスを証明するアカウント
     * amount as uint96 bigendian wie単位の付与残高
     * height as uint32 bigendian ブロック高の数値
     * message as bytes16 HF識別子
     * sign[n] as byte64 署名
     */
    function makeSnapshot(bytes calldata _tx) public returns (int success)
    {
        address account=BytesLib.toAddress(_tx,0);//20
        uint96 amount=BytesLib.toUint96(_tx,20);  //12
        uint32 height=BytesLib.toUint32(_tx,32);  //4
        bytes calldata message=_tx[36:52];        //16

        require(hasSnapshot(account)==false);   //スナップショットがないこと
        require(amount>0);                      //生成数量が0よりおおきいこと
        require(height==FORK_HEIGHT);           //HFブロック高が同一であること
        require(BytesLib.bytesEquals(message,SIGN_MESSAGE));//メッセージが同じであること
        //require(msg.value==0); //payableじゃないからじゃないからいらない

        //焼却リストの確認
        for (uint i=0; i<BURN_ADDRS.length;i++){
            if(BURN_ADDRS[i]==account){
                return -1; //BURNリスト
            }
        }
        //署名検証
        bytes32 signe_hash=keccak256(BytesLib.slice(_tx,0,52));//署名のハッシュを生成
        for(uint i=0;i<PROOF_ADDRS.length;i++){
            bytes memory signe=BytesLib.slice(_tx,64+64*i,64);     //署名を取得
            if(ECDSA.recover(signe_hash,signe)!=PROOF_ADDRS[i]){
                return -2;
            }
        }
        
        //バランスを生成
        snapshot[account]=amount;    //スナップショットに数量を記録
        balances[account]=amount;    //バランスを生成
        
        //書き込み報酬を加算
        balances[msg.sender]=SafeMath.safeAdd(balanceOf(msg.sender),CALLER_PROFIT);
        //totalSupplyを更新する
        totalSupply=SafeMath.safeAdd(SafeMath.safeAdd(amount,CALLER_PROFIT),totalSupply);
        return 0;
    }
}


