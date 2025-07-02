// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibAppStorage} from "../../libraries/LibAppStorage.sol";
import {IGameFacet} from "../../interfaces/game/IGames.sol";

/**
 * @title GameFacet
 * @dev Handles game logic that interacts with both user and token systems
 */
contract GameFacet is IGameFacet {
    using LibAppStorage for LibAppStorage.AppStorage;

    function startGame(address opponent) external {
        LibAppStorage.requireNotPaused();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        if (!s.users[msg.sender].isActive) revert GameFacet__PlayerNotRegistered();
        if (!s.users[opponent].isActive) revert GameFacet__OpponentNotRegistered();
        if (s.playerStats[msg.sender].isPlaying) revert GameFacet__AlreadyInGame();
        if (s.playerStats[opponent].isPlaying) revert GameFacet__OpponentAlreadyInGame();

        s.playerStats[msg.sender].isPlaying = true;
        s.playerStats[opponent].isPlaying = true;

        emit GameStarted(msg.sender, opponent);
    }

    function finishGame(address player1, address player2, uint256 score1, uint256 score2) external {
        LibAppStorage.requireOperator();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        address winner = score1 > score2 ? player1 : player2;
        address loser = score1 > score2 ? player2 : player1;
        uint256 winnerScore = score1 > score2 ? score1 : score2;
        uint256 loserScore = score1 > score2 ? score2 : score1;

        // Update game stats
        s.playerStats[winner].wins++;
        s.playerStats[winner].totalScore += winnerScore;
        s.playerStats[winner].lastPlayedTime = block.timestamp;
        s.playerStats[winner].isPlaying = false;

        s.playerStats[loser].losses++;
        s.playerStats[loser].totalScore += loserScore;
        s.playerStats[loser].lastPlayedTime = block.timestamp;
        s.playerStats[loser].isPlaying = false;

        // Record game event
        s.gameHistory.push(
            LibAppStorage.GameEvent({
                player1: player1,
                player2: player2,
                winner: winner,
                timestamp: block.timestamp,
                scorePlayer1: score1,
                scorePlayer2: score2
            })
        );

        s.totalGamesPlayed++;

        // Award tokens to winner (interacting with token system)
        uint256 reward = winnerScore * 10; // 10 tokens per point
        s.tokenBalances[winner] += reward;
        s.totalSupply += reward;
        s.users[winner].totalTokensEarned += reward;

        // Check for new champion
        if (winnerScore > s.championScore) {
            s.currentChampion = winner;
            s.championScore = winnerScore;
            emit ChampionChanged(winner, winnerScore);
        }

        emit GameFinished(winner, loser, winnerScore, loserScore);
    }

    function getPlayerStats(address player) external view returns (LibAppStorage.GameStats memory) {
        return LibAppStorage.appStorage().playerStats[player];
    }

    function getCurrentChampion() external view returns (address champion, uint256 score) {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return (s.currentChampion, s.championScore);
    }

    function getGameHistory() external view returns (LibAppStorage.GameEvent[] memory) {
        return LibAppStorage.appStorage().gameHistory;
    }

    function getTotalGamesPlayed() external view returns (uint256) {
        return LibAppStorage.appStorage().totalGamesPlayed;
    }
}
