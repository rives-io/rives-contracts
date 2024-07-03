# Rives Contracts


## Build and deploy

```shell
make deploy
```

## Build and deploy on a specific chain

Create a `.env.<chain>` file with the following parameters: 

```
PRIVATE_KEY=
RPC_URL=
OPERATOR_ADDRESS=
DAPP_ADDRESS=
```

and run 

```shell
make deploy-<chain>
```

