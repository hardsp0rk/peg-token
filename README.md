# Peg Token

Upgradeable ERC20 token with gas-less transaction capability.

Contract conforms to [EIP-20](https://eips.ethereum.org/EIPS/eip-20), [EIP-712](https://eips.ethereum.org/EIPS/eip-712) and [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612).

## Setup

To install with [Foundry](https://github.com/foundry-rs/foundry):

```sh
forge install hardsp0rk/peg-token
```

## Test

```sh
forge test
```

## Build

```sh
forge build
```

## Deploy

Deploy sample token with Transparent Proxy [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967):
```sh
forge script script/DeployPegTokenBUSD.s.sol:DeployPegTokenBUSDScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```
