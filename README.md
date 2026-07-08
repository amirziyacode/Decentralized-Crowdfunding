# 🚀 Decentralized Crowdfunding

A decentralized crowdfunding platform built with Solidity and Foundry, allowing anyone to create fundraising campaigns, receive contributions in ETH, and securely manage campaign funds without relying on a centralized platform.

## ✨ Features

- 📌 Create fundraising campaigns
- 💰 Fund campaigns with ETH
- 🎯 Set funding goals and deadlines
- 💵 Campaign owners can withdraw funds after reaching the goal
- 🔄 Contributors can claim refunds if the funding goal is not met
- 🔒 Secure smart contract design using custom errors and the Checks-Effects-Interactions pattern
- 📢 Event emission for all important actions

---

## 🏗️ Project Structure

```
src/
├── Crowdfunding.sol

test/
├── Crowdfunding.t.sol

script/
├── DeployCrowdfunding.s.sol
```

---

## 📖 How It Works

### 1. Create Campaign

Anyone can create a campaign by providing:

- Title
- Description
- Funding Goal
- Campaign Duration

---

### 2. Fund Campaign

Users can contribute ETH to active campaigns before the deadline.

Each contribution is tracked individually.

---

### 3. Withdraw Funds

The campaign creator can withdraw the raised ETH only if:

- The campaign deadline has passed
- The funding goal has been reached
- Funds have not already been withdrawn

---

### 4. Refund

If the campaign fails to reach its funding goal before the deadline, contributors can withdraw their deposited ETH.

---

## 🔐 Security

This project follows several Solidity best practices:

- Custom Errors
- Checks-Effects-Interactions Pattern
- Input Validation
- Access Control
- Safe ETH Transfers using `call`
- Reentrancy-safe refund logic

---

## 🧪 Testing

Tests are written using **Foundry**.

Run all tests:

```bash
forge test
```
Coverage Test:





  ```bash
  forge coverage

  ```

Run tests with gas report:

```bash
forge test --gas-report
```

Run a specific test:

```bash
forge test --match-test testCreateCampaign
```

---

## 🚀 Deployment

Deploy using Foundry scripts:

```bash
forge script script/DeployCrowdfunding.s.sol \
--rpc-url <RPC_URL> \
--private-key <PRIVATE_KEY> \
--broadcast
```

---

## 📚 Tech Stack

- Solidity
- Foundry

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome.

Feel free to fork the repository and submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

**AmirAli**

GitHub: https://github.com/amirziyacode

If you found this project helpful, consider giving it a ⭐.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
