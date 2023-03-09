// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第三十一节 create2部署合约
 * 
 * 合约地址生成算法   
 * 
 * bytes memory packed = abi.encodePacked(
 *     uint8(0xff), // 255
 *     address(this), // 
 *     salt, // bytes32  // 
 *     keccak256(creationCode)  // bytes32 
 * )
 * bytes32 hash = keccak256( packed )
 * address newAddress = address(uint160(uint(hash)))
 */

contract Student {

    function getName() external pure returns(string memory) {
        return "Student::getName()";
    }

    function kill() external {
        selfdestruct(payable(tx.origin));
    }

}

contract Create2ByCreationCodeEP31 {

    address public student;

    function killStudent() external {
        Student(student).kill();
        student = address(0);
    }

    function callStudentName() external view returns(string memory) {
        return Student(student).getName();
    }

    function create2Student(string memory _salt) external returns(address tokenAddr) {
        bytes memory creationCode = getCreationCode();
        bytes32 _salt_hash = keccak256(abi.encodePacked(_salt));
        assembly {
            tokenAddr := create2(
                0, /* ETH wei */
                add(creationCode, 32), /* 32 bit = bytes.length */ 
                mload(creationCode), /* full size */ 
                _salt_hash /* byte32 salt */
            )
            if iszero(extcodesize(tokenAddr)) {
                revert(0, 0)
            }
            sstore(student.slot, tokenAddr)
        }
    }

    function create2Student(string memory _salt, bytes memory creationCode) external returns(address tokenAddr) {
        bytes32 _salt_hash = keccak256(abi.encodePacked(_salt));
        assembly {
            tokenAddr := create2(
                0, /* ETH wei */
                add(creationCode, 32), /* 32 bit = bytes.length */ 
                mload(creationCode), /* full size */ 
                _salt_hash /* byte32 salt */
            )
            if iszero(extcodesize(tokenAddr)) {
                revert(0, 0)
            }
            sstore(student.slot, tokenAddr)
        }
    }

    function makeStudent(string memory _salt) external returns(address) {
        return student = address(
            new Student{salt: keccak256(abi.encodePacked(_salt))}()
        );
    }

    function getAddress(string memory _salt) external view returns(address) {
        return address(uint160(uint(
            keccak256(
                abi.encodePacked(
                    uint8(0xff),
                    address(this),
                    keccak256(abi.encodePacked(_salt)),
                    keccak256(type(Student).creationCode)
                )
            )
        )));
    }

    function getCreationCode() public pure returns(bytes memory) {
        return type(Student).creationCode;
    }

}