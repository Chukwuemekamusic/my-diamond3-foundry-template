// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibAppStorage} from "../../libraries/LibAppStorage.sol";

interface IUserManagementFacet {
    // Errors
    error UserManagementFacet__UserAlreadyRegistered();
    error UserManagementFacet__InvalidUsername();
    error UserManagementFacet__UserNotFound();

    // Events
    event UserRegistered(address indexed user, string username);
    event UserLevelUp(address indexed user, uint256 newLevel);

    // Core functions
    function registerUser(string memory username) external;
    function getUserInfo(address user) external view returns (LibAppStorage.User memory);
    function levelUp(address user) external;
    function getTotalUsers() external view returns (uint256);
    function updateTokensEarned(address user, uint256 amount) external;
}
