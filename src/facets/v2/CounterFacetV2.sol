// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibDiamond} from "../../libraries/LibDiamond.sol";

// CounterFacetV2 - Contains all functions (existing + new)
contract CounterFacetV2 {
    bytes32 constant COUNTER_STORAGE_POSITION = keccak256("counter.storage");
    
    struct CounterStorage {
        uint256 count;
        mapping(address => uint256) userCounts;
    }
    
    function counterStorage() internal pure returns (CounterStorage storage cs) {
        bytes32 position = COUNTER_STORAGE_POSITION;
        assembly { cs.slot := position }
    }
     event CountIncremented(uint256 newCount);
    event CountDecremented(uint256 newCount);
    
    // Existing functions
    function increment() external {
        CounterStorage storage cs = counterStorage();
        cs.count += 1;
        cs.userCounts[msg.sender] += 1;
        emit CountIncremented(cs.count);
    }

    function decrement() external {
        CounterStorage storage cs = counterStorage();
        require(cs.count > 0, "Counter: cannot go below zero");
        cs.count -= 1;
        emit CountDecremented(cs.count);
    }

    function getCount() external view returns (uint256) {
        return counterStorage().count;
    }

    function getUserCount(address user) external view returns (uint256) {
        return counterStorage().userCounts[user];
    }

    function setCount(uint256 _count) external {
        LibDiamond.enforceIsContractOwner();
        counterStorage().count = _count;
    }
    
    // NEW function in V2
    function multiply(uint256 factor) external {
        CounterStorage storage cs = counterStorage();
        cs.count *= factor;
    }
}