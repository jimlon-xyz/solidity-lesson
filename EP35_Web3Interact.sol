// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Solidity 第三十五节 Web3合约交互
 *
 * 
 *    众筹合约 Vue3 + Web3.js 智能合约交互
 *          
 */

library AddressArray {

    function find(address[] memory addr, address search) internal pure returns(int) {
        for(uint n; n < addr.length; n++) {
            if (addr[n] == search) return int(n);
        }
        return -1;
    }

}

contract Web3InteractEP35 {

    using AddressArray for address[];

    enum State {
        Pending,
        Success,
        Fail
    }

    struct Activity {
        uint id;
        address creator;
        string title;
        string description;
        uint value;
        uint receiveAmount;  //receiveAmount
        uint deadline;
        uint minValue;
        uint minValuePercent;
        State state;
        uint finishedTime;
        uint failedTime;
        uint createdAt;
    }

    uint public activityId;
    Activity[] public activity;
    
    mapping(uint => address[]) activitySender; // 
    mapping(uint => mapping(address => uint)) activitySenderValue; // activityId => sender => value

    event Pay(uint activityId, address sender, uint value, uint timeAt);

    modifier formValidate(uint value, uint deadline, uint minValue, uint minValuePercent) {
        require(value > 0, "Must greater than 0");
        require(deadline > (block.timestamp + 15), "Deadline is invalid"); // POW 出块 约等于 15s
        require(minValue > 0, "Min value is invalid");
        require(minValuePercent >= 50, "Min value percent is invalid");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function createActivity(string[2] memory attr,  // [title, description]
        uint value,  // eth wei
        uint deadline, 
        uint minValue, 
        uint minValuePercent) external formValidate(value, deadline, minValue, minValuePercent) {

        Activity memory _activity;
        _activity.id = ++activityId;
        _activity.creator = msg.sender;
        _activity.title = attr[0]; // title
        _activity.description = attr[1]; // description
        _activity.value = value;
        _activity.deadline = deadline;
        _activity.minValue = minValue;
        _activity.minValuePercent = minValuePercent;
        _activity.state = State.Pending;
        _activity.createdAt = block.timestamp;

        activity.push(_activity);

    }

    function pay(uint _activityId) external payable {
        require(_activityId <= activityId, "Activity id is invalid");
        require(activity[ _activityId - 1 ].state == State.Pending, "Activity is finished");
        require(msg.value >= activity[ _activityId - 1 ].minValue, "Min value is invalid");
        require(activity[ _activityId - 1 ].deadline > block.timestamp, "Activity is expired");

        activity[ _activityId - 1 ].receiveAmount += msg.value;

        if (activitySender[_activityId].find(msg.sender) == -1)
            activitySender[_activityId].push(msg.sender);

        emit Pay(_activityId, msg.sender, msg.value, block.timestamp);

    }

    function finish(uint _activityId) external {
        require(_activityId <= activityId, "Activity id is invalid");
        require(activity[ _activityId - 1 ].state == State.Pending, "Activity is finished");
        require(activity[ _activityId - 1 ].creator == msg.sender, "Permission denied");

        if (activity[ _activityId - 1 ].receiveAmount >= activity[ _activityId - 1 ].value) {
            // finish
            uint value = activity[ _activityId - 1 ].receiveAmount;
            payable(activity[ _activityId - 1 ].creator).transfer(value);
            activity[ _activityId - 1 ].state = State.Success;
            activity[ _activityId - 1 ].finishedTime = block.timestamp;
        } else {
            if (block.timestamp >= activity[ _activityId - 1 ].deadline) {
                // fail
                for(uint n; n < activitySender[_activityId].length; n++) {
                    address sender = activitySender[_activityId][n];
                    uint value = activitySenderValue[_activityId][sender];
                    payable(sender).transfer(value);
                }
                activity[ _activityId - 1 ].state = State.Fail;
                activity[ _activityId - 1 ].failedTime = block.timestamp;
            }
        }

    }

    function getActivity(uint _activityId) external view returns(bool, Activity memory) {
        Activity memory _activity;
        if (_activityId > activityId || _activityId == 0) return (false, _activity);
        return (true, activity[_activityId - 1]);
    }

}