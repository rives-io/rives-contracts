
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

# tape ownership model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/TapeOwnershipModelVanguard3.sol:TapeOwnershipModelVanguard3)

TAPE_OWNERSHIP_MODEL=$(echo $result | jq -r '.deployedTo')


# tape asset
MAX_STEPS=100
MAX_SUPPLY=1000
RANGES="[1,5,1000]"
# COEFS="[10000,1000,2000]"
COEFS="[1000000000000000,1000000000000000,2000000000000000]"

ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $FEE_MODEL $TAPE_MODEL $TAPE_BOND_UTILS $TAPE_OWNERSHIP_MODEL $MAX_SUPPLY $RANGES $COEFS"

result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/Tape.sol:Tape --constructor-args $ARGS)

TAPE_CONTRACT=$(echo $result | jq -r '.deployedTo')
echo $TAPE_CONTRACT


# configuration 
cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $TAPE_CONTRACT "addDapp(address)" $DAPP_ADDRESS

cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $TAPE_CONTRACT "setBaseURI(string)" "https://vanguard.rives.io/tapes/"


# remix configuration
<<EOF

0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,100,0x992277F0207E67AEEF20beb2Cb6221295425656B,0xC3Ca70388Fd19bEE0340Afd49A74B3D464309a5C,0x51A0dfea63768e7827e9AAA532314910648F3eD2,0xd20977056F58b3Fb3533b7C2b9028a19Fbcd2358,1000,["1","3","1000"],["10000","1000","2000"]


0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,100,0x0000000000000000000000000000000000000000,0x66E401739C38789640b04465145E20Bd3B6BD614,0x71e3404D69E70CA2a2f4E82d095BbdBA443336dC,0xD2457926Dc6A49AfbD479E840ae44F86a921C5f1,0x2A778f111db48Ff42c243076d09a0966F65ADB17,1000,["1","3","1000"],["10000","1000","2000"]


0x0000000000000000000000000000000000000000000000000000000000000001,1



0x0000000000000000000000000000000000000000000000000000000000000001,1,1000000



0x0000000000000000000000000000000000000000000000000000000000000001,1,7000



0x0000000000000000000000000000000000000000000000000000000000000001


0x0000000000000000000000000000000000000000000000000000000000000001,["1","3"],["10000","1000"]


0x0000000000000000000000000000000000000000000000000000000000000001,["10","11","30"],["0","10000","1000"]


EOF