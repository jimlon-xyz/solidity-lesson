// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第二十九节 Multi Call
 *
 */


contract TestFirst {

    string public name;

    function setName(string memory _name) external {
        name = _name;
    }

}

contract TestSecond {

    uint8 public gender;

    function setGender(uint8 _gender) external {
        gender = _gender;
    }

}


// 0 = 0x568864A892a1B25127018Be020d2AF585Dff6c96
// 1 = 0x9B90AD58bc5D129E343603C262fa7a3dec8C94e9


// 0 staticcall 0x06fdde0300000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000

// 1 staticcall 0x79caad8600000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000



// 0 call 0xc47f0027000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000047465737400000000000000000000000000000000000000000000000000000000
// 1 call 0xc871cb8b0000000000000000000000000000000000000000000000000000000000000064



contract MultiCallEP29 {

    address[2] public addr;

    event Log(address indexed addr);

    function makeFirst() external {
        addr[0] = address(new TestFirst());
    }

    function makeSecond() external {
        addr[1] = address(new TestSecond());
    }

    function makeCalldata(string memory fn, uint8 args) external pure returns(bytes memory) {
        return abi.encodeWithSignature(fn, args);
    }

    function makeCalldata(string memory fn, string memory args) external pure returns(bytes memory) {
        return abi.encodeWithSignature(fn, args);
    }

    function multiRead(bytes[2] memory _calldata) external view returns(
        string memory name,  // 隐式变量  不需要 return 不需要重新定义变量
        uint8 gender) {
        
        (bool ok, bytes memory _result) = addr[0].staticcall(_calldata[0]);
        require(ok, "Multi[0] read failed");

        name = abi.decode(_result, (string));

        (ok, _result) = addr[1].staticcall(_calldata[1]);
        require(ok, "Multi[1] read failed");

        gender = abi.decode(_result, (uint8));

    }

    function multiWrite(bytes[2] memory _calldata, uint[2] memory weiValue) external {
        (bool ok,) = addr[0].call{value: weiValue[0]}(_calldata[0]);
        require(ok, "Multi[0] read failed");
        (ok,) = addr[1].call{value: weiValue[1]}(_calldata[1]);
        require(ok, "Multi[1] read failed");
    }


}