// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

import {ExampleFacet} from "../src/facets/ExampleFacet.sol";
import {Example2Facet} from "../src/facets/Example2Facet.sol";

contract AddFacets is Script {
    address DIAMOND_ADDRESS = vm.envAddress("DIAMOND_ADDRESS");

    function run() external {
        console.log("Using Diamond at:", DIAMOND_ADDRESS);

        vm.startBroadcast();

        // Deploy new facets
        ExampleFacet exampleFacet = new ExampleFacet();
        Example2Facet example2Facet = new Example2Facet();

        console.log("ExampleFacet deployed at:", address(exampleFacet));
        console.log("Example2Facet deployed at:", address(example2Facet));

        // Build cut struct for adding both facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // Add ExampleFacet
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(exampleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getExampleFacetSelectors()
        });

        // Add Example2Facet
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(example2Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getExample2FacetSelectors()
        });

        // Execute the diamond cut
        IDiamondCut(DIAMOND_ADDRESS).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        console.log("Successfully added both facets to diamond!");

        // Verify using loupe
        verifyWithLoupe(DIAMOND_ADDRESS);
    }

    function getExampleFacetSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](5);
        selectors[0] = ExampleFacet.exampleFunction1.selector;
        selectors[1] = ExampleFacet.exampleFunction2.selector;
        selectors[2] = ExampleFacet.exampleFunction3.selector;
        selectors[3] = ExampleFacet.exampleFunction4.selector;
        selectors[4] = ExampleFacet.exampleFunction5.selector;

        console.log("ExampleFacet selectors:");
        for (uint256 i = 0; i < selectors.length; i++) {
            console.logBytes4(selectors[i]);
        }
    }

    function getExample2FacetSelectors() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](5);
        selectors[0] = Example2Facet.example2Function1.selector;
        selectors[1] = Example2Facet.example2Function2.selector;
        selectors[2] = Example2Facet.example2Function3.selector;
        selectors[3] = Example2Facet.example2Function4.selector;
        selectors[4] = Example2Facet.example2Function5.selector;

        console.log("Example2Facet selectors:");
        for (uint256 i = 0; i < selectors.length; i++) {
            console.logBytes4(selectors[i]);
        }
    }

    function verifyWithLoupe(address diamondAddress) internal view {
        console.log("Verifying with Diamond Loupe...");

        IDiamondLoupe loupe = IDiamondLoupe(diamondAddress);

        // Get all facets
        address[] memory facetAddresses = loupe.facetAddresses();
        console.log("Total facets after addition:", facetAddresses.length);

        // Check if our functions are mapped
        address exampleFacetAddr = loupe.facetAddress(ExampleFacet.exampleFunction1.selector);
        address example2FacetAddr = loupe.facetAddress(Example2Facet.example2Function1.selector);

        if (exampleFacetAddr != address(0)) {
            console.log("ExampleFacet functions found at:", exampleFacetAddr);
        } else {
            console.log("ExampleFacet functions not found");
        }

        if (example2FacetAddr != address(0)) {
            console.log("Example2Facet functions found at:", example2FacetAddr);
        } else {
            console.log("Example2Facet functions not found");
        }
    }
}
