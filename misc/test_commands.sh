
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

# tape fee model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/TapeFixedFeeVanguard3.sol:TapeFixedFeeVanguard3)

TAPE_FEE_MODEL=$(echo $result | jq -r '.deployedTo')

# tape model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/TapeModelVanguard3.sol:TapeModelVanguard3)

TAPE_MODEL=$(echo $result | jq -r '.deployedTo')

# ownership model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/OwnershipModelVanguard3.sol:OwnershipModelVanguard3)

OWNERSHIP_MODEL=$(echo $result | jq -r '.deployedTo')

# ownership model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/BondingCurveModelVanguard3.sol:BondingCurveModelVanguard3)

BC_MODEL=$(echo $result | jq -r '.deployedTo')

# tape bond utils ''
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/TapeBondUtils.sol:TapeBondUtils)

TAPE_BOND_UTILS=$(echo $result | jq -r '.deployedTo')


# tape asset
MAX_STEPS=100
MAX_SUPPLY=1000
RANGES="[1,5,1000]"
# COEFS="[10000,1000,2000]"
COEFS="[1000000000000000,1000000000000000,2000000000000000]"

ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $TAPE_FEE_MODEL $TAPE_MODEL $OWNERSHIP_MODEL $BC_MODEL $TAPE_BOND_UTILS $MAX_SUPPLY $RANGES $COEFS"

result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/Tape.sol:Tape --constructor-args $ARGS)

TAPE_CONTRACT=$(echo $result | jq -r '.deployedTo')
echo $TAPE_CONTRACT


# configuration 
cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $TAPE_CONTRACT "addDapp(address)" $DAPP_ADDRESS

cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $TAPE_CONTRACT "setBaseURI(string)" "https://vanguard.rives.io/tapes/{id}"




# cartridge fee model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/CartridgeFixedFeeVanguard3.sol:CartridgeFixedFeeVanguard3)

CARTRIDGE_FEE_MODEL=$(echo $result | jq -r '.deployedTo')

# cartridge model
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/CartridgeModelVanguard3.sol:CartridgeModelVanguard3)

CARTRIDGE_MODEL=$(echo $result | jq -r '.deployedTo')

# cartridge bond utils ''
result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/CartridgeBondUtils.sol:CartridgeBondUtils)

CARTRIDGE_BOND_UTILS=$(echo $result | jq -r '.deployedTo')


# cartridge asset
MAX_STEPS=100
MAX_SUPPLY=1000
RANGES="[1,5,1000]"
# COEFS="[10000,1000,2000]"
COEFS="[1000000000000000,1000000000000000,2000000000000000]"

ARGS="$OPERATOR $MAX_STEPS $CURRENCY_TOKEN $CARTRIDGE_FEE_MODEL $CARTRIDGE_MODEL $OWNERSHIP_MODEL $BC_MODEL $CARTRIDGE_BOND_UTILS $MAX_SUPPLY $RANGES $COEFS"

result=$(forge create --rpc-url "$RPC_URL" --private-key "$PRIV_KEY" --json src/Cartridge.sol:Cartridge --constructor-args $ARGS)

CARTRIDGE_CONTRACT=$(echo $result | jq -r '.deployedTo')
echo $CARTRIDGE_CONTRACT


# configuration 
cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $CARTRIDGE_CONTRACT "addDapp(address)" $DAPP_ADDRESS

cast send --private-key "$PRIV_KEY" --rpc-url $RPC_URL $CARTRIDGE_CONTRACT "setBaseURI(string)" "https://vanguard.rives.io/cartridges/{id}"


# remix configuration
<<EOF


0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
100,
0x0000000000000000000000000000000000000000,
0x66E401739C38789640b04465145E20Bd3B6BD614,
0x71e3404D69E70CA2a2f4E82d095BbdBA443336dC,
0x2A778f111db48Ff42c243076d09a0966F65ADB17,
0x79D71168d866115d4bec4a4913d49AB956911274,
0xC56778EcEBA28e3D1912999d39de0Ec13266B9e7,
1000,
5,
["1","3","1000"],
["10000","1000","2000"]


0x0000000000000000000000000000000000000000000000000000000000000001,1



0x0000000000000000000000000000000000000000000000000000000000000001,1,1000000



0x0000000000000000000000000000000000000000000000000000000000000001,1,7000



0x0000000000000000000000000000000000000000000000000000000000000001


0x0000000000000000000000000000000000000000000000000000000000000001,["1","3"],["10000","1000"]


0x0000000000000000000000000000000000000000000000000000000000000001,["10","11","30"],["0","10000","1000"]





# TODO: use keccak as the hashto generate id (so it can be verified onchain) - ok
# TODO: separate bc validation to another interface and contract, add tape id as parameter (so it could be verified against cartridge bc rules) - ok
# TODO: add cartridge id to tape params to facilitate onchain verifications - ok





0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
100,
0x0000000000000000000000000000000000000000,
0xEF899724384f40905401fC81f35B015D85DD3d7c,
0x66dC81ae5C85A27D10f0D6E737A0FAA846F4A205,
0x64764dac98c39113498769A57A69742f562DC9fc,
0xf1f4d4219BEc8b2e5E26B3d52b36B0b6F167e145,
0x950B0e278696d7140F22aCaF476abD2080bbE37f,
1000,
5,
["1","3","1000"],
["10000","1000","2000"]



EOF