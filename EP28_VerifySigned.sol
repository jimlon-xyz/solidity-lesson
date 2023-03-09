// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第二十八节 签名验证
 *
 *  
 *      step 1  内容进  keccak256() bytes32
 *      step 2  通过当前账户 对 step 1 结果 （含有以太坊签名前缀字符串） 签名 
 *      step 3  通过 （含有签名前缀字符串）ETH哈希 + 签名结果  还原 签名 账户address
 *      step 4  验证签名  原始内容 + 签名结果 + 账户 address 校验 签名是否为 address 参数
 *          
 *      ethereum.enable()
 *      ethereum.request({"method": "personal_sign", param: [ hash, account ] }).then(_sig => {   })
 *
 */

contract VerifySignedEP28 {

    function msgHash(string memory _msg) public pure returns(bytes32) {
        return keccak256(bytes(_msg));
    }

    function signedHash(bytes32 _hash) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    function recoverSigner(bytes32 _ethHash, bytes calldata _sig) public pure returns(address) {
        bytes32 r = bytes32(_sig[:32]);
        bytes32 s = bytes32(_sig[32:64]);
        uint8 v = uint8(bytes1(_sig[64:]));
        return ecrecover(_ethHash, v, r, s);
    }

    function verify(string memory _msg, bytes calldata _sig, address signer) public pure returns(bool) {
        return recoverSigner(
            signedHash(msgHash(_msg)),
            _sig
        ) == signer;
    }


}