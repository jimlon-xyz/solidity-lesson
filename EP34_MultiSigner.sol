// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第三十四节 多签钱包
 *
 */

enum State {
    Pending,
    Approved,
    Rejected
}

struct Signer {
    address account;
    State state;
    uint signedAt;
}

library SignerArray {

    function find(Signer[] storage _signer, address addr) internal view returns(int) {
        for(uint n; n < _signer.length; n++) {
            if (_signer[n].account == addr) {
                return int(n);
            }
        }
        return -1;
    }

}

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

contract MultiSignEP34 {

    using SignerArray for Signer[];
    
    struct Transaction {
        uint id;
        string title;
        address to;
        uint value;
        bytes data;
        State state;
        uint[3] timeAt; // approvedAt, rejectedAt, createdAt
    }

    address[] public owner;
    uint public txId;

    mapping(uint => Signer[]) public transactionSigner; // txId => Signer[]

    Transaction[] transaction;

    event Commited(uint indexed txId, address indexed creator, string title, uint timeAt);
    event Approved(uint indexed txId, address indexed signer, uint timeAt);
    event Rejected(uint indexed txId, address indexed signer, uint timeAt);

    receive() external payable {}

    fallback() external payable {}

    constructor(address[] memory _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        bool ok; 
        for(uint n; n < owner.length; n++) {
            if (owner[n] == msg.sender) {
                ok = true;
                break;
            }
        }
        require(ok, "Permission denied");
        _;
    }

    modifier checkBefore(uint _txId) {
        require(_txId > 0 && _txId <= txId, "Trx does not exists");
        require(transaction[_txId - 1].state == State.Pending, "Trx was finished");
        require(transactionSigner[_txId].find(msg.sender) == -1, "Trx was signed");
        _;
    }

    function commit(string memory title, address to, uint value, bytes calldata data) external onlyOwner {
        Transaction memory trx;
        trx.id = ++txId;
        trx.title = title;
        trx.to = to;
        trx.value = value;
        trx.data = data;
        trx.state = State.Pending;
        trx.timeAt[2] = block.timestamp;
        transaction.push(trx);

        transactionSigner[txId].push(Signer({
            account: msg.sender,
            state: State.Approved,
            signedAt: block.timestamp
        }));

        emit Commited(trx.id, msg.sender, trx.title, block.timestamp);

    }

    function approved(uint _txId) external onlyOwner checkBefore(_txId)  {
        transactionSigner[_txId].push(Signer({
            account: msg.sender,
            state: State.Approved,
            signedAt: block.timestamp
        }));

        if (transactionSigner[_txId].length == owner.length) {

            transaction[_txId - 1].state = State.Approved;
            transaction[_txId - 1].timeAt[0] = block.timestamp;

            Transaction memory trx = transaction[_txId - 1];
            (bool ok,) = address(trx.to).call{value: trx.value}(trx.data);
            require(ok, "Execute failed");
        }

        emit Approved(_txId, msg.sender, block.timestamp);

    }

    function rejected(uint _txId) external onlyOwner checkBefore(_txId)  {

        transaction[_txId - 1].state = State.Rejected;
        transaction[_txId - 1].timeAt[1] = block.timestamp;

        transactionSigner[_txId].push(Signer({
            account: msg.sender,
            state: State.Rejected,
            signedAt: block.timestamp
        }));

        emit Rejected(_txId, msg.sender, block.timestamp);
    }

    function getTransactionList(
        State state, 
        uint pageNum, 
        uint pageSize) 
        external view returns(Transaction[] memory) {
        
        Transaction[] memory result = new Transaction[](pageSize);  // 5  3 {2}
        uint offset = pageNum <= 1 ? 0 : pageNum * pageSize;

        uint i;
        for(uint n = offset; n < transaction.length; n++) {
            if (transaction[n].state == state) {
                result[i] = transaction[n];
            }
            if (++i >= pageSize) break;
        }
        
        Transaction[] memory resultFilter = new Transaction[](i);
        for(uint k; k < i; k++) {
            resultFilter[k] = result[k];
        }
        return resultFilter;

    }


}