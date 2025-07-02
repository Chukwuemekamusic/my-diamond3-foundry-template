// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibAppStorage} from "../../libraries/LibAppStorage.sol";
import {IUserManagementFacet} from "../../interfaces/game/IUserManagementFacet.sol";

/**
 * @title UserManagementFacet
 * @dev Handles user registration and profile management
 */
contract UserManagementFacet is IUserManagementFacet {
    using LibAppStorage for LibAppStorage.AppStorage;

    function registerUser(string memory username) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        if (s.users[msg.sender].isActive) revert UserManagementFacet__UserAlreadyRegistered();
        if (bytes(username).length == 0) revert UserManagementFacet__InvalidUsername();

        s.users[msg.sender] = LibAppStorage.User({
            username: username,
            joinDate: block.timestamp,
            level: 1,
            isActive: true,
            totalTokensEarned: 0
        });

        s.totalUsers++;
        emit UserRegistered(msg.sender, username);
    }

    function getUserInfo(address user) external view returns (LibAppStorage.User memory) {
        return LibAppStorage.appStorage().users[user];
    }

    function levelUp(address user) external {
        LibAppStorage.requireOperator();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        if (!s.users[user].isActive) revert UserManagementFacet__UserNotFound();
        s.users[user].level++;

        emit UserLevelUp(user, s.users[user].level);
    }

    function getTotalUsers() external view returns (uint256) {
        return LibAppStorage.appStorage().totalUsers;
    }

    function updateTokensEarned(address user, uint256 amount) external {
        LibAppStorage.requireOperator();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        s.users[user].totalTokensEarned += amount;
    }
}
