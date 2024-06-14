
#!/bin/sh


# anvil configuration

PRIV_KEY='0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
RPC_URL=http://127.0.0.1:8545

OPERATOR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

DAPP_ADDRESS=0xab7528bb862fb57e8a2bcd567a2e929a0be56a5e





###
# deploy contracts

# Token
# result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/CurrencyToken.sol:CurrencyToken)

# CURRENCY_TOKEN=$(echo $result | jq -r '.deployedTo')
CURRENCY_TOKEN=0x0000000000000000000000000000000000000000

# Fee model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/TapeFixedFeeVanguard3.sol:TapeFixedFeeVanguard3)

FEE_MODEL=$(echo $result | jq -r '.deployedTo')

# tape model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/TapeModelVanguard3.sol:TapeModelVanguard3)

TAPE_MODEL=$(echo $result | jq -r '.deployedTo')

# bond utils ''
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/TapeBondUtils.sol:TapeBondUtils)

TAPE_BOND_UTILS=$(echo $result | jq -r '.deployedTo')


# tape asset
MAX_STEPS=100
MAX_SUPPLY=1000
RANGES="[1,5,1000]"
# COEFS="[10000,1000,2000]"
COEFS="[1000000000000000,1000000000000000,2000000000000000]"

ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $FEE_MODEL $TAPE_MODEL $TAPE_BOND_UTILS $MAX_SUPPLY $RANGES $COEFS"

result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/Tape.sol:Tape --constructor-args $ARGS)

TAPE_CONTRACT=$(echo $result | jq -r '.deployedTo')
echo $TAPE_CONTRACT


# configuration 
cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $TAPE_CONTRACT "addDapp(address)" $DAPP_ADDRESS

cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $TAPE_CONTRACT "setBaseURI(string)" "https://vanguard.rives.io/tapes/"


# remix configuration
<<EOF

0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,100,0x992277F0207E67AEEF20beb2Cb6221295425656B,0xC3Ca70388Fd19bEE0340Afd49A74B3D464309a5C,0x51A0dfea63768e7827e9AAA532314910648F3eD2,0xd20977056F58b3Fb3533b7C2b9028a19Fbcd2358,1000,["1","3","1000"],["10000","1000","2000"]


0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,100,0x0000000000000000000000000000000000000000,0x2F3b05feF6265F8574CbC9900A8c581c993fEae6,0x5A606B5F9535c13B2F8DC12B3b976e9dC11427e6,0x78c4E798b65f1c96c4eEC6f5F93E51584593e723,1000,["1","3","1000"],["10000","1000","2000"]


0x0000000000000000000000000000000000000000000000000000000000000001,1



0x0000000000000000000000000000000000000000000000000000000000000001,1,1000000



0x0000000000000000000000000000000000000000000000000000000000000001,1,7000



0x0000000000000000000000000000000000000000000000000000000000000001




EOF