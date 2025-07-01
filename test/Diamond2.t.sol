// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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
import {LibDiamond} from "../src/libraries/LibDiamond.sol";

import {ExampleFacet} from "../src/facets/ExampleFacet.sol";
import {CounterFacet} from "../src/facets/CounterFacet.sol";
import {DeployDiamond} from "../script/DiamondTestScript.s.sol";

contract DiamondTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    CounterFacet counterFacet;
    DiamondInit diamondInit;

    address owner;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        DeployDiamond deployDiamond = new DeployDiamond();
        (diamond, counterFacet, ownershipFacet) = deployDiamond.run();
        owner = OwnershipFacet(address(diamond)).owner();
    }

    function testSetUpRuns() public {
        address deployerAddress = vm.envAddress("OWNER_ADDRESS");

        assertTrue(owner == deployerAddress);
    }

    function testDiamondDeployment() public {
        // Test that diamond is deployed correctly
        vm.startPrank(owner);
        assertTrue(address(diamond) != address(0));

        // Test ownership
        address currentOwner = OwnershipFacet(address(diamond)).owner();
        assertEq(currentOwner, owner);

        // Test facet count
        address[] memory facetAddresses = IDiamondLoupe(address(diamond)).facetAddresses();
        assertEq(facetAddresses.length, 4);
        vm.stopPrank();
    }

    function testCounterFunctionality() public {
        CounterFacet counter = CounterFacet(address(diamond));

        // Initial state
        assertEq(counter.getCount(), 0);
        assertEq(counter.getUserCount(user1), 0);

        // User1 increments
        vm.prank(user1);
        counter.increment();
        assertEq(counter.getCount(), 1);
        assertEq(counter.getUserCount(user1), 1);

        // User2 increments
        vm.prank(user2);
        counter.increment();
        assertEq(counter.getCount(), 2);
        assertEq(counter.getUserCount(user1), 1);
        assertEq(counter.getUserCount(user2), 1);

        // Decrement
        counter.decrement();
        assertEq(counter.getCount(), 1);

        // Owner can set count
        vm.prank(owner);
        counter.setCount(100);
        assertEq(counter.getCount(), 100);

        // Non-owner cannot set count
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibDiamond.NotContractOwner.selector, user1, owner));
        counter.setCount(200);
    }

    function testCounterEvents() public {
        CounterFacet counter = CounterFacet(address(diamond));

        // Test increment event
        vm.expectEmit(true, true, true, true);
        emit CountIncremented(1);
        counter.increment();

        // Test decrement event
        vm.expectEmit(true, true, true, true);
        emit CountDecremented(0);
        counter.decrement();
    }

    // Events for testing
    event CountIncremented(uint256 newCount);
    event CountDecremented(uint256 newCount);

    function testOwnershipTransfer() public {
        OwnershipFacet ownership = OwnershipFacet(address(diamond));
        
        // Initial owner
        assertEq(ownership.owner(), owner);
        
        // Transfer ownership
        vm.prank(owner);
        ownership.transferOwnership(user1);
        assertEq(ownership.owner(), user1);
        
        // Only new owner can transfer
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(LibDiamond.NotContractOwner.selector, owner, user1));
        ownership.transferOwnership(user2);
        
        // New owner can transfer
        vm.prank(user1);
        ownership.transferOwnership(user2);
        assertEq(ownership.owner(), user2);
    }

    function testLoupeFunctions() public {
        IDiamondLoupe loupe = IDiamondLoupe(address(diamond));
        
        // Test facetAddresses
        address[] memory addresses = loupe.facetAddresses();
        assertEq(addresses.length, 4);
        
        // Test facets
        IDiamondLoupe.Facet[] memory facets = loupe.facets();
        assertEq(facets.length, 4);
        
        // Test facetAddress lookup
        address facetAddr = loupe.facetAddress(CounterFacet.increment.selector);
        assertEq(facetAddr, address(counterFacet));
        
        // Test facetFunctionSelectors
        bytes4[] memory selectors = loupe.facetFunctionSelectors(address(counterFacet));
        assertEq(selectors.length, 5);
        
        // Test supportsInterface
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IERC165).interfaceId));
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondCut).interfaceId));
        assertTrue(IERC165(address(diamond)).supportsInterface(type(IDiamondLoupe).interfaceId));
    }
}
