// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibAppStorage} from "../../libraries/LibAppStorage.sol";

/**
 * @title TokenFacet
 * @dev Handles token operations that interact with user data
 */
contract TokenFacet {
    error TokenFacet__UserNotRegistered();

    using LibAppStorage for LibAppStorage.AppStorage;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TokensAwarded(address indexed user, uint256 amount, string reason);
    event TokenInitialized(string name, string symbol, uint256 totalSupply);

    error TokenFacet__InsufficientBalance();

    function initializeToken(string memory name, string memory symbol) external {
        LibAppStorage.requireAdmin();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        s.tokenName = name;
        s.tokenSymbol = symbol;
        s.totalSupply = 1000000000000000000000000000;

        emit TokenInitialized(name, symbol, s.totalSupply);
    }

    function awardTokens(address user, uint256 amount, string memory reason) external {
        LibAppStorage.requireOperator();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        if (!s.users[user].isActive) revert TokenFacet__UserNotRegistered();

        s.tokenBalances[user] += amount;
        s.totalSupply += amount;

        // Update user's total earned (calling shared state)
        s.users[user].totalTokensEarned += amount;

        // Record transaction
        s.transactions[s.nextTransactionId] = LibAppStorage.Transaction({
            from: address(0),
            to: user,
            amount: amount,
            timestamp: block.timestamp,
            transactionType: reason
        });
        s.nextTransactionId++;

        emit TokensAwarded(user, amount, reason);
        emit Transfer(address(0), user, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        if (!s.users[msg.sender].isActive) revert TokenFacet__UserNotRegistered();
        if (!s.users[to].isActive) revert TokenFacet__UserNotRegistered();
        if (s.tokenBalances[msg.sender] < amount) revert TokenFacet__InsufficientBalance();

        return _transfer(msg.sender, to, amount);
    }

    function balanceOf(address user) external view returns (uint256) {
        return LibAppStorage.appStorage().tokenBalances[user];
    }

    function totalSupply() external view returns (uint256) {
        return LibAppStorage.appStorage().totalSupply;
    }

    function tokenInfo() external view returns (string memory name, string memory symbol) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return (s.tokenName, s.tokenSymbol);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        s.tokenBalances[_from] -= _amount;
        s.tokenBalances[_to] += _amount;

        s.transactions[s.nextTransactionId] = LibAppStorage.Transaction({
            from: _from,
            to: _to,
            amount: _amount,
            timestamp: block.timestamp,
            transactionType: "transfer"
        });
        s.nextTransactionId++;

        emit Transfer(_from, _to, _amount);
        return true;
    }
}
