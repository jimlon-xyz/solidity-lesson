// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第三十三节 时间锁合约
 * 
 */

interface IERC20Metadata {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8); // 小数点的精度
    function totalSupply() external view returns (uint256);  // 总供应量
    function balanceOf(address account) external view returns (uint256); // 余额
    function transfer(address to, uint256 amount) external returns (bool); // 转账方法
    function allowance(address owner, address spender) external view returns (uint256); // 查询授权额度
    function approve(address spender, uint256 amount) external returns (bool); // 授权
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    // A 授权 B 10000 Token  B transferFrom(A, C, 100)

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract TimeLockEP33 {

    event Locked(address indexed tokenAddr, address indexed tokenOwner, uint amount, uint expireAt);
    event Withdrawed(address indexed tokenAddr, address indexed tokenOwner, uint amount, uint timeAt);

    // tokenAddr => tokenOwner => [ amount, expire ]
    mapping(address => mapping(address => uint[2])) lockAttr; // [amount, expire]

    function lock(address tokenAddr, uint amount, uint expireAt) external {
        require(expireAt > block.timestamp && 
            expireAt >= lockAttr[tokenAddr][msg.sender][1], "Expire is invalid");
        
        bool ok = IERC20Metadata(tokenAddr).transferFrom(msg.sender, address(this), amount);
        require(ok, "TransferFrom fail");

        lockAttr[tokenAddr][msg.sender][0] += amount;
        lockAttr[tokenAddr][msg.sender][1] = expireAt > lockAttr[tokenAddr][msg.sender][1] ? 
            expireAt : 
            lockAttr[tokenAddr][msg.sender][1];

        emit Locked(tokenAddr, msg.sender, amount, expireAt);
    }

    function getExpire(address tokenAddr, address tokenOwner) external view returns(uint) {
        return lockAttr[tokenAddr][tokenOwner][1] > block.timestamp ? lockAttr[tokenAddr][tokenOwner][1] : 0;
    }

    function getAmount(address tokenAddr, address tokenOwner) external view returns(uint) {
        return lockAttr[tokenAddr][tokenOwner][0];
    }

    function withdraw(address tokenAddr) external {
        require(lockAttr[tokenAddr][msg.sender][0] > 0, "Out of token");
        require(lockAttr[tokenAddr][msg.sender][1] <= block.timestamp, "Not expire");
        uint amount = lockAttr[tokenAddr][msg.sender][0];
        IERC20Metadata(tokenAddr).transfer(msg.sender, amount);
        lockAttr[tokenAddr][msg.sender][0] = 0;

        emit Withdrawed(tokenAddr, msg.sender, amount, block.timestamp);
    }

    function getTime() external view returns(uint) {
        return block.timestamp + 120;
    }

}