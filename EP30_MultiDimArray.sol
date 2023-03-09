// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第三十节 多维数组
 *
 */

contract MultiDimArrayEP30 {

    function normalArray() external pure returns(uint[][] memory) {

        uint[][] memory id = new uint[][](3);

        //uint[3] id;
        //uint[] id = new uint[](3);

        for(uint n; n < id.length; n++) {
            id[n] = new uint[](2);
            id[n][0] = 100 + n;
            id[n][1] = 200 + n;
        }

        return id;

    }

    // uint[2][3]     [ [0,1], [0,1], [0,1] ]
    function fixedArray() external pure returns(uint[2][3] memory v  /* 隐式返回  */) {
        for(uint n; n < v.length; n++) {
            v[n][0] = n; 
            v[n][1] = 200 + n;
        }
    }

}