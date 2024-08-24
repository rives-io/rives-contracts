/*
 * The supported chains.
 * By default, there are only two chains here:
 *
 * - mudFoundry, the chain running on anvil that pnpm dev
 *   starts by default. It is similar to the viem anvil chain
 *   (see https://viem.sh/docs/clients/test.html), but with the
 *   basefee set to zero to avoid transaction fees.
 * - latticeTestnet, our public test network.
 *
 */

import { MUDChain, mudFoundry, redstone, garnet, base } from "@latticexyz/common/chains";
import { defineChain } from 'viem'

/*
 * See https://mud.dev/tutorials/minimal/deploy#run-the-user-interface
 * for instructions on how to add networks.
 */

export const rivesDevnetChain = defineChain({
    id: 42069,
    name: 'Rives Devnet',
    nativeCurrency: {
      decimals: 18,
      name: 'Rives Ether',
      symbol: 'RETH',
    },
    rpcUrls: {
      default: {
        http: ['https://anvil.dev.rives.io'],
        webSocket: ['wss://anvil.dev.rives.io'],
      },
    },
});


export const baseSepoliaChain = defineChain({
  id: 84532,
  name: 'Base Sepolia',
  nativeCurrency: {
    decimals: 18,
    name: 'BaseSepolia Ether',
    symbol: 'BSETH',
  },
  rpcUrls: {
    default: {
      http: ['https://base-sepolia-rpc.publicnode.com'],
      webSocket: ['wss://base-sepolia-rpc.publicnode.com'],
    },
  },
});

export const supportedChains: MUDChain[] = [mudFoundry, redstone, garnet, rivesDevnetChain, baseSepoliaChain];
