// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {CounterFacetV2} from "../../../src/facets/v2/CounterFacetV2.sol";
import {IDiamondCut} from "../../../src/interfaces/IDiamondCut.sol";
import {CounterFacet} from "../../../src/facets/CounterFacet.sol";
import {CounterFacetV2} from "../../../src/facets/v2/CounterFacetV2.sol";

contract UpgradeToV2 is Script {
    address DIAMOND_ADDRESS = vm.envAddress("DIAMOND_ADDRESS");

    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast();

        CounterFacetV2 counterV2 = new CounterFacetV2();

        // Single replace with ALL selectors (existing + new)
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = CounterFacetV2.increment.selector;
        selectors[1] = CounterFacetV2.decrement.selector;
        selectors[2] = CounterFacetV2.getCount.selector;
        selectors[3] = CounterFacetV2.getUserCount.selector;
        selectors[4] = CounterFacetV2.setCount.selector;
        // selectors[5] = CounterFacetV2.multiply.selector;  // New function

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(counterV2),
            action: IDiamondCut.FacetCutAction.Replace, // Single replace
            functionSelectors: selectors
        });

        // Add new function
        bytes4[] memory newSelectors = new bytes4[](1);
        newSelectors[0] = CounterFacetV2.multiply.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(counterV2),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: newSelectors
        });

        IDiamondCut(DIAMOND_ADDRESS).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        console.log("Upgraded to CounterFacetV2:", address(counterV2));
        console.log("All functions now use V2 implementation");
    }
}
