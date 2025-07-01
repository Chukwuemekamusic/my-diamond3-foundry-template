// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

contract InspectDiamond is Script {
    // Replace with your deployed diamond address
    address constant DIAMOND_ADDRESS = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;

    function run() external view {
        console.log("=== DIAMOND INSPECTION ===");
        console.log("Diamond Address:", DIAMOND_ADDRESS);
        console.log("");

        inspectFacets();
        inspectSpecificSelectors();
    }

    function inspectFacets() internal view {
        IDiamondLoupe loupe = IDiamondLoupe(DIAMOND_ADDRESS);

        // Get all facet addresses
        address[] memory facetAddresses = loupe.facetAddresses();
        console.log("Total Facets:", facetAddresses.length);
        console.log("");

        // Inspect each facet
        for (uint256 i = 0; i < facetAddresses.length; i++) {
            address facetAddr = facetAddresses[i];
            bytes4[] memory selectors = loupe.facetFunctionSelectors(facetAddr);

            console.log("Facet", i + 1, ":");
            console.log("  Address:", facetAddr);
            console.log("  Functions:", selectors.length);

            // Log each function selector
            for (uint256 j = 0; j < selectors.length; j++) {
                console.log("    Selector", j + 1, ":", vm.toString(selectors[j]));

                // Try to identify common functions
                if (selectors[j] == 0x1f931c1c) {
                    console.log("      ^ diamondCut");
                } else if (selectors[j] == 0x7a0ed627) {
                    console.log("      ^ facets");
                } else if (selectors[j] == 0x52ef6b2c) {
                    console.log("      ^ facetAddresses");
                } else if (selectors[j] == 0xadfca15e) {
                    console.log("      ^ facetFunctionSelectors");
                } else if (selectors[j] == 0xcdffacc6) {
                    console.log("      ^ facetAddress");
                } else if (selectors[j] == 0x8da5cb5b) {
                    console.log("      ^ owner");
                } else if (selectors[j] == 0xf2fde38b) {
                    console.log("      ^ transferOwnership");
                } else if (selectors[j] == 0x01ffc9a7) {
                    console.log("      ^ supportsInterface");
                }
            }
            console.log("");
        }
    }

    function inspectSpecificSelectors() internal view {
        IDiamondLoupe loupe = IDiamondLoupe(DIAMOND_ADDRESS);

        console.log("=== FUNCTION SELECTOR LOOKUP ===");

        // Check for your example functions
        bytes4[] memory testSelectors = new bytes4[](10);
        string[] memory testNames = new string[](10);

        // ExampleFacet selectors
        testSelectors[0] = bytes4(keccak256("exampleFunction1()"));
        testNames[0] = "exampleFunction1";
        testSelectors[1] = bytes4(keccak256("exampleFunction2()"));
        testNames[1] = "exampleFunction2";
        testSelectors[2] = bytes4(keccak256("exampleFunction3()"));
        testNames[2] = "exampleFunction3";
        testSelectors[3] = bytes4(keccak256("exampleFunction4()"));
        testNames[3] = "exampleFunction4";
        testSelectors[4] = bytes4(keccak256("exampleFunction5()"));
        testNames[4] = "exampleFunction5";

        // Example2Facet selectors
        testSelectors[5] = bytes4(keccak256("example2Function1()"));
        testNames[5] = "example2Function1";
        testSelectors[6] = bytes4(keccak256("example2Function2()"));
        testNames[6] = "example2Function2";
        testSelectors[7] = bytes4(keccak256("example2Function3()"));
        testNames[7] = "example2Function3";
        testSelectors[8] = bytes4(keccak256("example2Function4()"));
        testNames[8] = "example2Function4";
        testSelectors[9] = bytes4(keccak256("example2Function5()"));
        testNames[9] = "example2Function5";

        for (uint256 i = 0; i < testSelectors.length; i++) {
            address facetAddr = loupe.facetAddress(testSelectors[i]);
            if (facetAddr != address(0)) {
                console.log(testNames[i], "-> Found at:", facetAddr);
            } else {
                console.log(testNames[i], "-> NOT FOUND");
            }
        }

        console.log("");
        console.log("=== INSPECTION COMPLETE ===");
    }
}
