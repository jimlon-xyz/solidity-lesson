// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第三十二节 ERC20合约
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

contract ERC20TokenEP32 is IERC20Metadata {

    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) approves;

 
    constructor(
        string memory _name_, 
        string memory _symbol_, 
        uint8 _decimals_,
        uint _totalSupply_ ) {
        
        _name = _name_;
        _symbol = _symbol_;
        _decimals = _decimals_;
        _totalSupply = _totalSupply_;

        balances[msg.sender] += _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external override view returns(string memory) {
        return _name;
    }

    function symbol() external override view returns(string memory) {
        return _symbol;
    }

    function decimals() external override view returns(uint8) {
        return _decimals;
    }

    function totalSupply() external override view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return approves[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(approves[msg.sender][spender] == 0, "ERC20: Spender is approved");
        approves[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(approves[from][msg.sender] > 0, "ERC20: Out of approval funds");
        approves[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint amount) internal returns(bool) {
        require(balances[from] >= amount, "ERC20: Out of funds");

        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }

}