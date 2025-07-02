// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibAppStorage} from "../../libraries/LibAppStorage.sol";

/**
 * @title AdminFacet
 * @dev System administration that can access all shared state
 */
contract AdminFacet {
    error AdminFacet__AlreadyInitialized();

    using LibAppStorage for LibAppStorage.AppStorage;

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event SystemPaused(bool paused);

    function initializeSystem(address admin) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        if (s.admin != address(0)) revert AdminFacet__AlreadyInitialized();

        s.admin = admin;
        s.systemPaused = false;
        s.systemFee = 100; // 1%
    }

    function transferAdmin(address newAdmin) external {
        LibAppStorage.requireAdmin();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        address oldAdmin = s.admin;
        s.admin = newAdmin;

        emit AdminChanged(oldAdmin, newAdmin);
    }

    function addOperator(address operator) external {
        LibAppStorage.requireAdmin();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        s.authorizedOperators[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) external {
        LibAppStorage.requireAdmin();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        s.authorizedOperators[operator] = false;
        emit OperatorRemoved(operator);
    }

    function pauseSystem(bool paused) external {
        LibAppStorage.requireAdmin();
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        s.systemPaused = paused;
        emit SystemPaused(paused);
    }

    function getSystemStatus()
        external
        view
        returns (
            address admin,
            bool paused,
            uint256 totalUsers,
            uint256 totalSupply,
            uint256 totalGames,
            address champion
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        return (s.admin, s.systemPaused, s.totalUsers, s.totalSupply, s.totalGamesPlayed, s.currentChampion);
    }

    function getTransactionHistory(uint256 startId, uint256 count)
        external
        view
        returns (LibAppStorage.Transaction[] memory)
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();

        uint256 endId = startId + count;
        if (endId > s.nextTransactionId) {
            endId = s.nextTransactionId;
        }

        LibAppStorage.Transaction[] memory transactions = new LibAppStorage.Transaction[](endId - startId);

        for (uint256 i = startId; i < endId; i++) {
            transactions[i - startId] = s.transactions[i];
        }

        return transactions;
    }
}
