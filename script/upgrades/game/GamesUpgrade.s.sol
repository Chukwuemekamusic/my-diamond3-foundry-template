// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {UserManagementFacet} from "../../../src/facets/game/UserManagementFacet.sol";
import {TokenFacet} from "../../../src/facets/game/TokenFacet.sol";
import {GameFacet} from "../../../src/facets/game/GameFacet.sol";
import {AdminFacet} from "../../../src/facets/game/AdminFacet.sol";

import {IDiamondCut} from "../../../src/interfaces/IDiamondCut.sol";

contract DeploySharedStateFacets is Script {
    address DIAMOND_ADDRESS = vm.envAddress("DIAMOND_ADDRESS");

    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast();

        // Deploy all facets
        UserManagementFacet userFacet = new UserManagementFacet();
        TokenFacet tokenFacet = new TokenFacet();
        GameFacet gameFacet = new GameFacet();
        AdminFacet adminFacet = new AdminFacet();

        console.log("UserManagementFacet:", address(userFacet));
        console.log("TokenFacet:", address(tokenFacet));
        console.log("GameFacet:", address(gameFacet));
        console.log("AdminFacet:", address(adminFacet));

        // Build diamond cuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](4);

        // Add UserManagementFacet
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(userFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getUserManagementSelectors()
        });

        // Add TokenFacet
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(tokenFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getTokenSelectors()
        });

        // Add GameFacet
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(gameFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getGameSelectors()
        });

        // Add AdminFacet
        cuts[3] = IDiamondCut.FacetCut({
            facetAddress: address(adminFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getAdminSelectors()
        });

        // Execute diamond cut
        IDiamondCut(DIAMOND_ADDRESS).diamondCut(cuts, address(0), "");

        // Initialize the system
        AdminFacet(DIAMOND_ADDRESS).initializeSystem(msg.sender);
        TokenFacet(DIAMOND_ADDRESS).initializeToken("GameToken", "GAME");

        vm.stopBroadcast();

        console.log("All facets deployed and initialized!");

        // Demo the shared state
        demonstrateSharedState();
    }

    function getUserManagementSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = UserManagementFacet.registerUser.selector;
        selectors[1] = UserManagementFacet.getUserInfo.selector;
        selectors[2] = UserManagementFacet.levelUp.selector;
        selectors[3] = UserManagementFacet.getTotalUsers.selector;
        selectors[4] = UserManagementFacet.updateTokensEarned.selector;
        return selectors;
    }

    function getTokenSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = TokenFacet.initializeToken.selector;
        selectors[1] = TokenFacet.awardTokens.selector;
        selectors[2] = TokenFacet.transfer.selector;
        selectors[3] = TokenFacet.balanceOf.selector;
        selectors[4] = TokenFacet.totalSupply.selector;
        selectors[5] = TokenFacet.tokenInfo.selector;
        return selectors;
    }

    function getGameSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = GameFacet.startGame.selector;
        selectors[1] = GameFacet.finishGame.selector;
        selectors[2] = GameFacet.getPlayerStats.selector;
        selectors[3] = GameFacet.getCurrentChampion.selector;
        selectors[4] = GameFacet.getGameHistory.selector;
        selectors[5] = GameFacet.getTotalGamesPlayed.selector;
        return selectors;
    }

    function getAdminSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = AdminFacet.initializeSystem.selector;
        selectors[1] = AdminFacet.transferAdmin.selector;
        selectors[2] = AdminFacet.addOperator.selector;
        selectors[3] = AdminFacet.removeOperator.selector;
        selectors[4] = AdminFacet.pauseSystem.selector;
        selectors[5] = AdminFacet.getSystemStatus.selector;
        selectors[6] = AdminFacet.getTransactionHistory.selector;
        return selectors;
    }

    function demonstrateSharedState() internal view {
        console.log("=== DEMONSTRATING SHARED STATE ===");

        // Check system status
        (address admin, bool paused, uint256 users, uint256 supply, uint256 games, address champion) =
            AdminFacet(DIAMOND_ADDRESS).getSystemStatus();

        console.log("Admin:", admin);
        console.log("System paused:", paused);
        console.log("Total users:", users);
        console.log("Token supply:", supply);
        console.log("Total games:", games);
        console.log("Current champion:", champion);

        // Check token info
        (string memory name, string memory symbol) = TokenFacet(DIAMOND_ADDRESS).tokenInfo();
        console.log("Token name:", name);
        console.log("Token symbol:", symbol);
    }
}
