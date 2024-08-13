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

import { MUDChain, mudFoundry, redstone, garnet } from "@latticexyz/common/chains";
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

export const supportedChains: MUDChain[] = [mudFoundry, redstone, garnet, rivesDevnetChain];
