# Makefile

ENVFILE := .env
DEPLOYFILE := .deploy

SHELL := /bin/bash

all: build

build:
	forge build


deploy: --load-env
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployTape.s.sol  --rpc-url ${RPC_URL} --broadcast
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/SetupTape.s.sol  --rpc-url ${RPC_URL} --broadcast
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/SetupCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast

deploy-%: ${ENVFILE}.%
	@$(eval include include $<)
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployTape.s.sol  --rpc-url ${RPC_URL} --broadcast
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/SetupTape.s.sol  --rpc-url ${RPC_URL} --broadcast
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast
	PRIVATE_KEY=${PRIVATE_KEY} DAPP_ADDRESS=${DAPP_ADDRESS} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/SetupCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast

# Aux env targets
--load-env: ${ENVFILE}
	$(eval include include $(PWD)/${ENVFILE})

${ENVFILE}:
	@test ! -f $@ && echo "$(ENVFILE) not found. Creating with default values" 
	echo PRIVATE_KEY='0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' >> $(ENVFILE)
	echo RPC_URL=http://127.0.0.1:8545 >> $(ENVFILE)
	echo OPERATOR_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 >> $(ENVFILE)
	echo DAPP_ADDRESS=0xab7528bb862fb57e8a2bcd567a2e929a0be56a5e >> $(ENVFILE)

--load-env-%: ${ENVFILE}.%
	@$(eval include include $^)

${ENVFILE}.%:
	test ! -f $@ && $(error "file $@ doesn't exist")

