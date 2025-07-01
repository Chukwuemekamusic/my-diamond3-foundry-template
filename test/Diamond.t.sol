// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondInit} from "../src/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";

import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";
import {IERC173} from "../src/interfaces/IERC173.sol";

import {ExampleFacet} from "../src/facets/ExampleFacet.sol";
// import {FacetWithAppStorage} from "../src/facets/FacetWithAppStorage.sol";
// import {FacetWithAppStorage2, ExampleEnum} from "../src/facets/FacetWithAppStorage2.sol";

// import {ERC20Facet} from "../src/facets/ERC20Facet.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
// import {ERC1155Facet} from "../src/facets/ERC1155Facet.sol";
// import {IERC1155Facet} from "../src/interfaces/IERC1155Facet.sol";

contract DiamondUnitTest is Test {
    Diamond diamond;
    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;

    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    ExampleFacet exampleFacet;
    // FacetWithAppStorage facetWithAppStorage;
    // FacetWithAppStorage2 facetWithAppStorage2;

    // ERC20Facet erc20Facet;
    // ERC1155Facet erc1155Facet;

    address diamondOwner = address(0x1337DAD);
    address alice = address(0xA11C3);
    address bob = address(0xB0B);

    address[] facetAddressList;

    function setUp() public {
        // Deploy core diamond template contracts
        diamondInit = new DiamondInit();
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        diamond = new Diamond(diamondOwner, address(diamondCutFacet));

        // Create the `cuts` array. (Already cut DiamondCut during diamond deployment)
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);

        // Get function selectors for facets for `cuts` array.
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = IERC165.supportsInterface.selector;

        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = IERC173.owner.selector;
        ownershipSelectors[1] = IERC173.transferOwnership.selector;

        // Populate the `cuts` array with the needed data.
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Upgrade our diamond with the remaining facets by making the cuts. Must be owner!
        vm.prank(diamondOwner);
        IDiamondCut(address(diamond)).diamondCut(cuts, address(diamondInit), abi.encodeWithSignature("init()"));

        facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses(); // save all facet addresses

        // Set interfaces for less verbose diamond interactions.
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));
    }

    function test_Deployment() public view {
        // All 3 facets have been added to the diamond, and are not 0x0 address.
        assertEq(facetAddressList.length, 3, "Cut, Loupe, Ownership");
        assertNotEq(facetAddressList[0], address(0), "Not 0x0 address");
        assertNotEq(facetAddressList[1], address(0), "Not 0x0 address");
        assertNotEq(facetAddressList[2], address(0), "Not 0x0 address");

        // Owner is set correctly?
        assertEq(IERC173(address(diamond)).owner(), diamondOwner, "Diamond owner set properly");

        // Interface support set to true during `init()` call during Diamond upgrade?
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC165).interfaceId), "IERC165");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC173).interfaceId), "IERC173");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId), "Cut");
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId), "Loupe");
        // assertTrue(IERC165(address(diamond)).supportsInterface(0x36372b07), "IERC20");
        // assertTrue(IERC165(address(diamond)).supportsInterface(0xa219a025), "IERC20MetaData");
        // assertTrue(IERC165(address(diamond)).supportsInterface(0xd9b67a26), "IERC1155");
        // assertTrue(IERC165(address(diamond)).supportsInterface(0x0e89341c), "IERC1155MetadataURI");

        // Facets have the correct function selectors?
        bytes4[] memory loupeViewCut = ILoupe.facetFunctionSelectors(facetAddressList[0]); // DiamondCut
        bytes4[] memory loupeViewLoupe = ILoupe.facetFunctionSelectors(facetAddressList[1]); // Loupe
        bytes4[] memory loupeViewOwnership = ILoupe.facetFunctionSelectors(facetAddressList[2]); // Ownership
        assertEq(loupeViewCut[0], IDiamondCut.diamondCut.selector, "should match");
        assertEq(loupeViewLoupe[0], IDiamondLoupe.facets.selector, "should match");
        assertEq(loupeViewLoupe[1], IDiamondLoupe.facetFunctionSelectors.selector, "should match");
        assertEq(loupeViewLoupe[2], IDiamondLoupe.facetAddresses.selector, "should match");
        assertEq(loupeViewLoupe[3], IDiamondLoupe.facetAddress.selector, "should match");
        assertEq(loupeViewLoupe[4], IERC165.supportsInterface.selector, "should match");
        assertEq(loupeViewOwnership[0], IERC173.owner.selector, "should match");
        assertEq(loupeViewOwnership[1], IERC173.transferOwnership.selector, "should match");

        // Function selectors are associated with the correct facets?
        assertEq(facetAddressList[0], ILoupe.facetAddress(IDiamondCut.diamondCut.selector), "should match");
        assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facets.selector), "should match");
        assertEq(
            facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetFunctionSelectors.selector), "should match"
        );
        assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetAddresses.selector), "should match");
        assertEq(facetAddressList[1], ILoupe.facetAddress(IDiamondLoupe.facetAddress.selector), "should match");
        assertEq(facetAddressList[1], ILoupe.facetAddress(IERC165.supportsInterface.selector), "should match");
        assertEq(facetAddressList[2], ILoupe.facetAddress(IERC173.owner.selector), "should match");
        assertEq(facetAddressList[2], ILoupe.facetAddress(IERC173.transferOwnership.selector), "should match");
    }

    // Tests Add, Replace, and Remove functionality for ExampleFacet
    function test_AddReplaceRemove() public {
        // Deploy another facet
        exampleFacet = new ExampleFacet();

        // We create and populate array of function selectors needed for the cut of ExampleFacet.
        bytes4[] memory exampleSelectors = new bytes4[](5);
        exampleSelectors[0] = ExampleFacet.exampleFunction1.selector;
        exampleSelectors[1] = ExampleFacet.exampleFunction2.selector;
        exampleSelectors[2] = ExampleFacet.exampleFunction3.selector;
        exampleSelectors[3] = ExampleFacet.exampleFunction4.selector;
        exampleSelectors[4] = ExampleFacet.exampleFunction5.selector;

        // Make the cut
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(exampleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: exampleSelectors
        });

        // Upgrade diamond with ExampleFacet cut. No need to init anything special/new.
        vm.prank(diamondOwner);
        ICut.diamondCut(cut, address(0x0), "");

        // Update testing variable `facetAddressList` with our new facet by calling `facetAddresses()`.
        facetAddressList = IDiamondLoupe(address(diamond)).facetAddresses();

        // 4 facets should now be in the Diamond. And the new one is valid.
        assertEq(facetAddressList.length, 4, "Cut, Loupe, Ownership, ExampleFacet");
        assertNotEq(facetAddressList[3], address(0), "ExampleFacet is not 0x0 address");

        // New facet has the correct function selectors?
        bytes4[] memory loupeViewExample = ILoupe.facetFunctionSelectors(facetAddressList[3]); // ExampleFacet
        assertEq(loupeViewExample[0], ExampleFacet.exampleFunction1.selector, "should match");
        assertEq(loupeViewExample[1], ExampleFacet.exampleFunction2.selector, "should match");
        assertEq(loupeViewExample[2], ExampleFacet.exampleFunction3.selector, "should match");
        assertEq(loupeViewExample[3], ExampleFacet.exampleFunction4.selector, "should match");
        assertEq(loupeViewExample[4], ExampleFacet.exampleFunction5.selector, "should match");

        // Function selectors are associated with the correct facet.
        assertEq(facetAddressList[3], ILoupe.facetAddress(ExampleFacet.exampleFunction1.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(ExampleFacet.exampleFunction2.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(ExampleFacet.exampleFunction3.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(ExampleFacet.exampleFunction4.selector), "should match");
        assertEq(facetAddressList[3], ILoupe.facetAddress(ExampleFacet.exampleFunction5.selector), "should match");

        // We can successfully call the ExampleFacet functions.
        ExampleFacet(address(diamond)).exampleFunction1();
        ExampleFacet(address(diamond)).exampleFunction2();
        ExampleFacet(address(diamond)).exampleFunction3();
        ExampleFacet(address(diamond)).exampleFunction4();
        ExampleFacet(address(diamond)).exampleFunction5();

        // We can successfully replace a function and put it in a different facet.
        bytes4[] memory selectorToReplace = new bytes4[](1);
        selectorToReplace[0] = ExampleFacet.exampleFunction1.selector;

        // Make the cut
        IDiamondCut.FacetCut[] memory replaceCut = new IDiamondCut.FacetCut[](1);

        replaceCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectorToReplace
        });

        vm.prank(diamondOwner);
        ICut.diamondCut(replaceCut, address(0), "");

        // The exampleFunction1 now lives in ownershipFacet and not ExampleFacet.
        assertEq(address(ownershipFacet), ILoupe.facetAddress(ExampleFacet.exampleFunction1.selector));

        // Double checking, the Ownership facet now has the new function selector
        bytes4[] memory loupeViewOwnership = ILoupe.facetFunctionSelectors(facetAddressList[2]); // Ownership
        assertEq(loupeViewOwnership[0], IERC173.owner.selector, "should match");
        assertEq(loupeViewOwnership[1], IERC173.transferOwnership.selector, "should match");
        assertEq(loupeViewOwnership[2], ExampleFacet.exampleFunction1.selector, "should match");

        // The ExampleFacet no longer has access to the exampleFunction1
        vm.expectRevert();
        ExampleFacet(address(diamond)).exampleFunction1();

        // We can also remove functions completely by housing them in 0x0.
        bytes4[] memory selectorsToRemove = new bytes4[](2);
        selectorsToRemove[0] = ExampleFacet.exampleFunction2.selector;
        selectorsToRemove[1] = ExampleFacet.exampleFunction3.selector;

        // Make the cut
        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);

        removeCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectorsToRemove
        });

        // Remove the functions via the removeCut
        vm.prank(diamondOwner);
        ICut.diamondCut(removeCut, address(0), "");

        // Functions cannot be called and no longer exist in the diamond.
        vm.expectRevert();
        ExampleFacet(address(diamond)).exampleFunction2();
        vm.expectRevert();
        ExampleFacet(address(diamond)).exampleFunction3();

        // The exampleFunction2 and 3 now live at 0x0.
        assertEq(address(0), ILoupe.facetAddress(ExampleFacet.exampleFunction2.selector));
        assertEq(address(0), ILoupe.facetAddress(ExampleFacet.exampleFunction3.selector));

        // Note: I have not changed the template in diamond-3 in any meaningful way.
        // Therefore, I did not include the cache bug test here b/c it is fixed in diamond-3.
    }
}
