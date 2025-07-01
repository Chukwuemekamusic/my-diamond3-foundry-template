// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDiamondCut {
    enum FacetCutAction {
        Add, // 0
        Replace, // 1
        Remove // 2

    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}
