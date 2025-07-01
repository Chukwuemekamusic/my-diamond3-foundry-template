// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

import {ExampleFacet} from "../src/facets/ExampleFacet.sol";
import {Example2Facet} from "../src/facets/Example2Facet.sol";

contract RemnoveFunctions is Script {
    address DIAMOND_ADDRESS = vm.envAddress("DIAMOND_ADDRESS");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        removeSpecificFunctions();

        vm.stopBroadcast();
        console.log("Function removal completed");

        verifyFunctionsRemoved();
    }

    function removeSpecificFunctions() internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory selectorsToRemove = new bytes4[](2);
        selectorsToRemove[0] = ExampleFacet.exampleFunction5.selector;
        selectorsToRemove[1] = Example2Facet.example2Function5.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectorsToRemove
        });

        IDiamondCut(DIAMOND_ADDRESS).diamondCut(cut, address(0), "");

        console.log("Removed exampleFunction5 and example2Function5");
    }

    function verifyFunctionsRemoved() internal {
        console.log("Verifying function removal...");

        // Test that removed functions are no longer available
        console.log("Testing exampleFunction5 (should fail):");
        try ExampleFacet(DIAMOND_ADDRESS).exampleFunction5() {
            console.log("exampleFunction5 still exists (unexpected)");
        } catch {
            console.log("exampleFunction5 successfully removed");
        }

        console.log("Testing exampleFunction5 (should fail):");
        try Example2Facet(DIAMOND_ADDRESS).example2Function5() {
            console.log("example2Function5 still exists (unexpected)");
        } catch {
            console.log("example2Function5 successfully removed");
        }

        // Test that remaining functions still work
        console.log("Testing exampleFunction1 (should work):");
        try ExampleFacet(DIAMOND_ADDRESS).exampleFunction1() {
            console.log("exampleFunction1 still working");
        } catch {
            console.log("exampleFunction1 failed (unexpected)");
        }

        console.log("Testing exampleFunction2 (should work):");
        try ExampleFacet(DIAMOND_ADDRESS).exampleFunction2() {
            console.log("exampleFunction2 still working");
        } catch {
            console.log("exampleFunction2 failed (unexpected)");
        }

        console.log("Verification complete!");
    }
}
