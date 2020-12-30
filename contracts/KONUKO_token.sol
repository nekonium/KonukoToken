pragma solidity ^0.4.9;
 
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
library SafeMath {
    uint256 constant public MAX_UINT256 =0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y){
            revert();
        }
        return x + y;
    }
    
    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y){
            revert();
        }
        return x - y;
    }
    
    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
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
library BytesLib {
    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }
    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }
        return tempUint;
    }
    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_start + 12 >= _start, "toUint96_overflow");
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }
    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_start + 16 >= _start, "toUint128_overflow");
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }
}





contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data);
}


contract ERC223Token
{
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    
    mapping(address => uint) balances;
    
    string public name    = "NUKO Fork Token.R3";
    string public symbol  = "KONUKO";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    uint constant NUM_OF_PROOF_ACCOUNTS = 4;
    uint constant HF_TARGET_HEIGHT = 580000;    
    
    constructor()
    {
        //Supply of 100 tokens with 18 decimals. (100 + 18 times zero)
        balances[0xdc8fE10C5e872e25Ac24dE310e60D88E4b7a22a1] = 100 * 10**uint(decimals);
        totalSupply = balances[0xdc8fE10C5e872e25Ac24dE310e60D88E4b7a22a1];
    }
  
  
    // Function to access name of token .
    function name() constant returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
    
  
    // // Function that is called when a user or another contract wants to transfer funds .
    // function transfer(address _to, uint _value, bytes _data, string _custom_fallback) returns (bool success) {
        
    //     if(isContract(_to)) {
    //         if (balanceOf(msg.sender) < _value){
    //             throw;
    //         }
    //         balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    //         balances[_to] = safeAdd(balanceOf(_to), _value);
    //         assert(_to.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data));
    //         Transfer(msg.sender, _to, _value, _data);
    //         return true;
    //     }else {
    //         return transferToAddress(_to, _value, _data);
    //     }
    // }
  

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) returns (bool success)
    {
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }else{
            return transferToAddress(_to, _value, empty);
        }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success)
    {
        if (balanceOf(msg.sender) < _value){
            revert();
        }
        balances[msg.sender] = SafeMath.safeSub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.safeAdd(balanceOf(_to), _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success)
    {
        if (balanceOf(msg.sender) < _value){
            revert();
        }
        balances[msg.sender] = SafeMath.safeSub(balanceOf(msg.sender), _value);
        balances[_to] = SafeMath.safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    
    function requestToken(bytes _tx)returns (int success)
    {
        address account=BytesLib.toAddress(_tx,0);
        uint32 height=BytesLib.toUint32(_tx,20); //uint4
        uint96 amount=BytesLib.toUint96(_tx,24); //uint12
        // bytes hash_=_tx[0:52];
        
        // for(int i=0;i<NUM_OF_PROOF_ACCOUNTS;i++){
        //     _tx[52+i:52+i+32]
        // }
        
        //署名パラメータの確認
    //     if(_height!=CcatToken.HF_TARGET_HEIGHT){
    //         return -1;
    //     }
    //     //address,to,height,amountの連結bytesの生成

    // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    // bytes32 prefixedHash = keccak256(prefix, hash);



    //     //署名アカウントの確認
    //     if
    //     balance[_to]=
    }

    
    
    
}


// pragma solidity >=0.7.0 <0.8.0;
// /**
//     https://github.com/Dexaran/ERC223Token


//  */

// import './ERC223_interface.sol';
// import './ERC223_receiving_contract.sol';
// import '././SafeMath.sol';
// /**
//  * @title Reference implementation of the ERC223 standard token.
//  */
// contract CcatToken is ERC223Interface
// {
//     using SafeMath for uint;
//     /** トークンの名前*/
//     string constant public name    = "Konuko.R3";
//     /** トークンのシンボル*/
//     string constant public symbol  = "KONUKO";
//     /** 小数点以下の桁数*/
//     uint8 constant public decimals = 8;

//     uint256 public totalSupply;

//     uint constant NUM_OF_PROOF_ACCOUNTS = 4;
//     uint constant HF_TARGET_HEIGHT = 580000;

//     // List of user balances.
//     mapping(address => uint) balances; 


//     function name() view returns (string _name) {
//         return name;
//     }
//     // Function to access symbol of token .
//     function symbol() view returns (string _symbol) {
//         return symbol;
//     }
//     // Function to access decimals of token .
//     function decimals() view returns (uint8 _decimals) {
//         return decimals;
//     }
//     // Function to access total supply of tokens .
//     function totalSupply() view returns (uint256 _totalSupply) {
//         return totalSupply;
//     }
//     function balanceOf(address _owner) public view returns (uint balance) {
//         return balances[_owner];
//     }



   
//     // Standard function transfer similar to ERC20 transfer with no _data .
//     // Added due to backwards compatibility reasons .
//     function transfer(address _to, uint _value) returns (bool success) {
//         //standard function transfer similar to ERC20 transfer with no _data
//         //added due to backwards compatibility reasons
//         bytes memory empty;
//         if(isContract(_to)) {
//             return transferToContract(_to, _value, empty);
//         }else {
//             return transferToAddress(_to, _value, empty);
//         }
//     } 

//     // Function that is called when a user or another contract wants to transfer funds .
//     function transfer(address _to, uint _value, bytes _data) returns (bool success) {
//         if(isContract(_to)) {
//             return transferToContract(_to, _value, _data);
//         }else {
//             return transferToAddress(_to, _value, _data);
//         }
//     }


//     //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
//     function isContract(address _addr) private returns (bool is_contract) {
//         uint length;
//         assembly {
//             //retrieve the size of the code on target address, this needs assembly
//             length := extcodesize(_addr)
//         }
//         return (length>0);
//     }

//     //function that is called when transaction target is an address
//     function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
//         if (balanceOf(msg.sender) < _value){
//             throw;
//         }
//         balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
//         balances[_to] = safeAdd(balanceOf(_to), _value);
//         Transfer(msg.sender, _to, _value, _data);
//         return true;
//     }

//     //function that is called when transaction target is a contract
//     function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
//         if (balanceOf(msg.sender) < _value){
//             throw;
//         }
//         balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
//         balances[_to] = safeAdd(balanceOf(_to), _value);
//         ContractReceiver receiver = ContractReceiver(_to);
//         receiver.tokenFallback(msg.sender, _value, _data);
//         Transfer(msg.sender, _to, _value, _data);
//         return true;
//     }











//     function bytesToAddress(bytes bys) private pure returns (address addr) {
//         assembly {
//             addr := mload(add(bys,20))
//         } 
//     }
//     function sliceUint(bytes bs, uint start) internal pure returns (uint)
//     {
//         require(bs.length >= start + 32, "slicing out of range");
//         uint x;
//         assembly {
//             x := mload(add(bs, add(0x20, start)))
//         }
//         return x;
//     }


//     }




    

// }
