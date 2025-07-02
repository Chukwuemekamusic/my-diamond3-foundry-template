// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibAppStorage} from "../../libraries/LibAppStorage.sol";

// Define interfaces for each facet
// interface IUserManagementFacet {
//     error UserManagementFacet__UserAlreadyRegistered();
//     error UserManagementFacet__InvalidUsername();
//     error UserManagementFacet__UserNotFound();

//     event UserRegistered(address indexed user, string username);
//     event UserLevelUp(address indexed user, uint256 newLevel);

//     function registerUser(string memory username) external;
//     function getUserInfo(address user) external view returns (LibAppStorage.User memory);
//     function levelUp(address user) external;
//     function getTotalUsers() external view returns (uint256);
//     function updateTokensEarned(address user, uint256 amount) external;
// }

interface ITokenFacet {
    error TokenFacet__InsufficientBalance();
    error TokenFacet__UserNotRegistered();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TokensAwarded(address indexed user, uint256 amount, string reason);

    function awardTokens(address user, uint256 amount, string memory reason) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IGameFacet {
    error GameFacet__PlayerNotRegistered();
    error GameFacet__OpponentNotRegistered();
    error GameFacet__AlreadyInGame();
    error GameFacet__OpponentAlreadyInGame();

    event GameStarted(address indexed player1, address indexed player2);
    event GameFinished(address indexed winner, address indexed loser, uint256 winnerScore, uint256 loserScore);
    event ChampionChanged(address indexed newChampion, uint256 score);

    function startGame(address opponent) external;
    function finishGame(address player1, address player2, uint256 score1, uint256 score2) external;
    function getPlayerStats(address player) external view returns (LibAppStorage.GameStats memory);
}
