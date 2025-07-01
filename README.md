# Diamond-3 Foundry Template

A template and guide for building EIP-2535 Diamond Standard contracts using [Foundry](https://book.getfoundry.sh/).

## Overview

This repository provides a modular smart contract architecture using the Diamond Standard (EIP-2535), implemented with the Foundry toolchain. It includes example facets, deployment scripts, and tests to help you get started quickly.

## Structure

- `src/` — Core contracts (Diamond, Facets, Libraries, Interfaces)
- `script/` — Deployment and upgrade scripts
- `test/` — Foundry tests

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed (`forge`, `anvil`)
- Node.js and npm (for some scripts, optional)

### Install Dependencies

```sh
forge install
```

### Build Contracts

```sh
forge build
```

### Run Local Node

```sh
anvil
```

### Deploy Diamond

Simulate deployment (dry run):

```sh
forge script script/Diamond.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 -vvvv
```

Broadcast deployment (actually deploys):

```sh
forge script script/Diamond.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --private-key <YOUR_KEY> --broadcast -vvvv
```

### Run Tests

```sh
forge test -vvv
```

## Customization

- Add new facets in `src/facets/`
- Update deployment scripts in `script/`
- Write tests in `test/`

## References

- [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535)
- [Foundry Book](https://book.getfoundry.sh/)

---

_This is a template. Adapt it to your project as needed!_
