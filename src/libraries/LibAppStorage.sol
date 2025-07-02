// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library LibAppStorage {
    error LibApp__AdminAccessRequired();
    error LibApp__OperatorAccessRequired();
    error LibApp__SystemPaused();

    bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    struct AppStorage {
        mapping(address => User) users;
        uint256 totalUsers;
        // Token system
        mapping(address => uint256) tokenBalances;
        uint256 totalSupply;
        string tokenName;
        string tokenSymbol;
        // Game state
        mapping(address => GameStats) playerStats;
        uint256 totalGamesPlayed;
        address currentChampion;
        uint256 championScore;
        // Global settings
        address admin;
        bool systemPaused;
        uint256 systemFee;
        mapping(address => bool) authorizedOperators;
        // Events/History
        GameEvent[] gameHistory;
        mapping(uint256 => Transaction) transactions;
        uint256 nextTransactionId;
    }

    struct User {
        string username;
        uint256 joinDate;
        uint256 level;
        bool isActive;
        uint256 totalTokensEarned;
    }

    struct GameStats {
        uint256 wins;
        uint256 losses;
        uint256 totalScore;
        uint256 lastPlayedTime;
        bool isPlaying;
    }

    struct GameEvent {
        address player1;
        address player2;
        address winner;
        uint256 timestamp;
        uint256 scorePlayer1;
        uint256 scorePlayer2;
    }

    struct Transaction {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        string transactionType;
    }

    function appStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // Helper functions for common operations
    function isAdmin(address user) internal view returns (bool) {
        return appStorage().admin == user;
    }

    function isOperator(address user) internal view returns (bool) {
        return appStorage().authorizedOperators[user] || isAdmin(user);
    }

    function requireAdmin() internal view {
        if (!isAdmin(msg.sender)) revert LibApp__AdminAccessRequired();
    }

    function requireOperator() internal view {
        if (!isOperator(msg.sender)) revert LibApp__OperatorAccessRequired();
    }

    function requireNotPaused() internal view {
        if (appStorage().systemPaused) revert LibApp__SystemPaused();
    }
}
