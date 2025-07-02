// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondInit} from "../src/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {CounterFacet} from "../src/facets/CounterFacet.sol";

import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamond} from "../src/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";
import {IERC173} from "../src/interfaces/IERC173.sol";

// Script to deploy a Diamond with CutFacet, LoupeFacet and OwnershipFacet
// This Script DOES NOT upgrade the diamond with any of the example facets.
contract DeployScript is Script {
    function run() external returns (Diamond) {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address owner = vm.envAddress("OWNER_ADDRESS");
        vm.startBroadcast();

        // Deploy Contracts
        DiamondInit diamondInit = new DiamondInit();
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        CounterFacet counterFacet = new CounterFacet();

        // Public address associated with the private key that launched this script is now the owner. (msg.sender).
        Diamond diamond = new Diamond(msg.sender, address(diamondCutFacet));
        console.log("Deployed Diamond.sol at address:", address(diamond));

        // We prepare an array of `cuts` that we want to upgrade our Diamond with.
        // The remaining cuts that we want the diamond to have are the Loupe and Ownership facets.
        // A `cut` is a facet, its associated functions, and the action (we want to add).
        // (DiamondCutFacet was already cut during Diamond deployment, cannot re-add again anyway).
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        // Populate the `cuts` array with all data needed for each `FacetCut` struct
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });

        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(counterFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: generateSelectors("CounterFacet")
        });

        // After we have all the cuts setup how we want, we can upgrade the diamond to include these facets.
        // We call `diamondCut` with our `diamond` contract through the `IDiamondCut` interface.
        // `diamondCut` takes in the `cuts` and the `DiamondInit` contract and calls its `init()` function.
        IDiamondCut(address(diamond)).diamondCut(cuts, address(diamondInit), abi.encodeWithSignature("init()"));

        // We use `IERC173` instead of an `IOwnershipFacet` interface for the `OwnershipFacet` with no problems
        // because all functions from `OwnershipFacet` are just IERC173 overrides.
        // However, for more complex facets that are not exactly 1:1 with an existing IERC,
        // you can create custom `IExampleFacet` interface that isn't just identical to an IERC.
        console.log("Diamond cuts complete. Owner of Diamond:", IERC173(address(diamond)).owner());

        vm.stopBroadcast();

        console.log("Diamond deployed:", address(diamond));
        console.log("DiamondCutFacet deployed:", address(diamondCutFacet));
        console.log("DiamondLoupeFacet deployed:", address(diamondLoupeFacet));
        console.log("OwnershipFacet deployed:", address(ownershipFacet));
        console.log("CounterFacet deployed:", address(counterFacet));
        console.log("DiamondInit deployed:", address(diamondInit));

        // Test the deployment
        test(address(diamond));
        return diamond;
    }

    function generateSelectors(string memory _facetName) internal pure returns (bytes4[] memory selectors) {
        if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("DiamondLoupeFacet"))) {
            selectors = new bytes4[](5);
            selectors[0] = IDiamondLoupe.facets.selector;
            selectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
            selectors[2] = IDiamondLoupe.facetAddresses.selector;
            selectors[3] = IDiamondLoupe.facetAddress.selector;
            selectors[4] = IERC165.supportsInterface.selector;
        } else if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("OwnershipFacet"))) {
            selectors = new bytes4[](2);
            selectors[0] = IERC173.owner.selector;
            selectors[1] = IERC173.transferOwnership.selector;
        } else if (keccak256(abi.encodePacked(_facetName)) == keccak256(abi.encodePacked("CounterFacet"))) {
            selectors = new bytes4[](5);
            selectors[0] = CounterFacet.increment.selector;
            selectors[1] = CounterFacet.decrement.selector;
            selectors[2] = CounterFacet.getCount.selector;
            selectors[3] = CounterFacet.getUserCount.selector;
            selectors[4] = CounterFacet.setCount.selector;
        }
    }

    function test(address _diamondAddress) internal view {
        // Test counter
        uint256 count = CounterFacet(_diamondAddress).getCount();
        console.log("Initial count:", count);

        // Test loupe
        address[] memory addresses = IDiamondLoupe(_diamondAddress).facetAddresses();
        console.log("Number of facets:", addresses.length);

        // Test ownership
        address owner = OwnershipFacet(_diamondAddress).owner();
        console.log("Owner:", owner);

        console.log("Diamond deployment successful!");
    }
}

/* 
                                        Tips

- There are many ways to get a function selector. `facets()` is 0x7a0ed627 for example.                                       
- Function Selector = First 4 bytes of a hashed function signature.
- Function Signature = Function name and it's parameter types. No spaces. "transfer(address,uint256)".

1. `Contract.function.selector` --> console.logBytes4(IDiamondLoupe.facets.selector);
2. `bytes4(keccak256("funcSig")` --> console.logBytes4(bytes4(keccak256("facets()")));
3. `bytes4(abi.encodeWithSignature("funcSig"))` --> console.logBytes4(bytes4(abi.encodeWithSignature("facets()"))); 
4. VSCode extension `Solidity Visual Developer` shows function selectors. Manual copy-paste.

*/

// // We create and populate array of function selectors needed for FacetCut Structs
// bytes4[] memory loupeSelectors = new bytes4[](5);
// loupeSelectors[0] = IDiamondLoupe.facets.selector;
// loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
// loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
// loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
// loupeSelectors[4] = IERC165.supportsInterface.selector; // The IERC165 function found in the Loupe.

// bytes4[] memory ownershipSelectors = new bytes4[](2);
// ownershipSelectors[0] = IERC173.owner.selector; // IERC173 has all the ownership functions needed.
// ownershipSelectors[1] = IERC173.transferOwnership.selector;
