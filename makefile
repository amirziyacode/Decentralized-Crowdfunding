-include .env

make build:
	@echo "Building the project..."
	@forge build


make test:
	@echo "Running tests..."
	@forge test

make deploy:
	@echo "Deploying the contract..."
	@forge script script/DecentralizedCrowdfundingDeploy.s.sol --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL) --broadcast
