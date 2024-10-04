# Rives Contracts

## Instructions

### Format

```shell
forge fmt
```

### Build and deploy

```shell
make deploy
```

### Build and deploy on a specific chain

Create a `.env.<chain>` file with the following parameters:

```
PRIVATE_KEY=
RPC_URL=
OPERATOR_ADDRESS=
DAPP_ADDRESS=
WORLD_ADDRESS=
CARTRIDGE_INSERTION_CONFIG=0x
INPUT_BOX_ADDRESS=0x59b22D57D4f067708AB0c00552767405926dc768
CARTRIDGE_ASSET_ADDRESS=
TAPE_ASSET_ADDRESS=
```

and run

```shell
make deploy-<chain>
```

As long as you use the same wallet the world, cartridge, tape addresses will be the same. If you don't have all values because you are running it for the first time, run each of the following steps in order and update the `.env.<chain>` file accordingly

```shell
make world-deploy-proxy-<chain>
```

Then update the world address. To get the dapp address, you could setup the proxy contract address in the application configuration (the InputBoxSystem address), then deploy the dapp. Next:

```shell
make contracts-deploy-assets-<chain>
```

Then update the cartridge and tape asset addresses. Finally:

```shell
make setup-proxy-<chain>
make setup-assets-<chain>
```
