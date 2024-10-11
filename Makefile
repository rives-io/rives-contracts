# Makefile

ENVFILE := .env
DEPLOYFILE := .deploy

SHELL := /bin/bash

WORLD_ADDRESS ?= 0x00124590193fcd497c0eed517103368113f89258

SALT ?= 0x0000000000000000000000000000000000000000000000000000000000000000

slither :; slither ./src

all: build build-proxy install-proxy-client

build:
	forge build

build-proxy: install-proxy
	cd proxy-contracts/ && pnpm mud tablegen
	cd proxy-contracts/ && pnpm mud worldgen

install-proxy:
	cd proxy-contracts/ && pnpm install

install-proxy-client:
	cd proxy-contracts/client && pnpm install


dev-client:
	cd proxy-contracts/client && pnpm run dev


# Deployments


# Local env
deploy: deploy-proxy deploy-assets
	@echo "deployed everything"

deploy-assets: contracts-deploy-assets setup-assets

contracts-deploy-assets: --load-env
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployTape.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}
setup-assets: --load-env
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} WORLD_ADDRESS=${WORLD_ADDRESS} DAPP_ADDRESS=${DAPP_ADDRESS} forge script script/SetupTape.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} WORLD_ADDRESS=${WORLD_ADDRESS} DAPP_ADDRESS=${DAPP_ADDRESS} forge script script/SetupCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}

deploy-proxy: world-deploy-proxy setup-proxy

world-deploy-proxy: --load-env
	cd proxy-contracts/ && PRIVATE_KEY=${PRIVATE_KEY} pnpm mud deploy --salt ${SALT} --rpc ${RPC_URL}
setup-proxy: --load-env
	cd proxy-contracts/ && PRIVATE_KEY=${PRIVATE_KEY} WORLD_ADDRESS=${WORLD_ADDRESS} DAPP_ADDRESS=${DAPP_ADDRESS} \
	 OPERATOR_ADDRESS=${OPERATOR_ADDRESS} CARTRIDGE_INSERTION_CONFIG=${CARTRIDGE_INSERTION_CONFIG} INPUT_BOX_ADDRESS=${INPUT_BOX_ADDRESS} \
	 CARTRIDGE_ASSET_ADDRESS=${CARTRIDGE_ASSET_ADDRESS} TAPE_ASSET_ADDRESS=${TAPE_ASSET_ADDRESS} \
	 forge script script/SetupResources.s.sol --rpc-url ${RPC_URL} --broadcast --sender ${OPERATOR_ADDRESS}

update-proxy: world-update-proxy seup-proxy

world-update-proxy: --load-env
	cd proxy-contracts/ && PRIVATE_KEY=${PRIVATE_KEY} pnpm mud deploy --salt ${SALT} --rpc ${RPC_URL} --world-address ${WORLD_ADDRESS}


# Alternative env
deploy-%: deploy-proxy-% deploy-assets-%
	@echo "deployed everything"

deploy-assets-%: conntracts-deploy-assets-% setup-assets-%

contracts-deploy-assets-%: ${ENVFILE}.%
	@$(eval include include $<)
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployTape.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} forge script script/DeployCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}

setup-assets-%: ${ENVFILE}.%
	@$(eval include include $<)
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} WORLD_ADDRESS=${WORLD_ADDRESS} DAPP_ADDRESS=${DAPP_ADDRESS} forge script script/SetupTape.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}
	PRIVATE_KEY=${PRIVATE_KEY} OPERATOR_ADDRESS=${OPERATOR_ADDRESS} WORLD_ADDRESS=${WORLD_ADDRESS} DAPP_ADDRESS=${DAPP_ADDRESS} forge script script/SetupCartridge.s.sol  --rpc-url ${RPC_URL} --broadcast --via-ir --sender ${OPERATOR_ADDRESS}

deploy-proxy-%: world-deploy-proxy-% setup-proxy-%
world-deploy-proxy-%: ${ENVFILE}.% 
	@$(eval include include $<)
	cd proxy-contracts/ && PRIVATE_KEY=${PRIVATE_KEY} pnpm mud deploy --salt ${SALT} --rpc ${RPC_URL}
setup-proxy-%: ${ENVFILE}.% 
	@$(eval include include $<)
	cd proxy-contracts/ && PRIVATE_KEY=${PRIVATE_KEY} WORLD_ADDRESS=${WORLD_ADDRESS} DAPP_ADDRESS=${DAPP_ADDRESS} \
	 OPERATOR_ADDRESS=${OPERATOR_ADDRESS} CARTRIDGE_INSERTION_CONFIG=${CARTRIDGE_INSERTION_CONFIG} INPUT_BOX_ADDRESS=${INPUT_BOX_ADDRESS} \
	 CARTRIDGE_ASSET_ADDRESS=${CARTRIDGE_ASSET_ADDRESS} TAPE_ASSET_ADDRESS=${TAPE_ASSET_ADDRESS} \
	 forge script script/SetupResources.s.sol --rpc-url ${RPC_URL} --broadcast --sender ${OPERATOR_ADDRESS}

update-proxy-%: world-update-proxy-% setup-proxy-%
world-update-proxy-%: ${ENVFILE}.% 
	@$(eval include include $<)
	cd proxy-contracts/ && PRIVATE_KEY=${PRIVATE_KEY} pnpm mud deploy --salt ${SALT} --rpc ${RPC_URL} --world-address ${WORLD_ADDRESS}


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

