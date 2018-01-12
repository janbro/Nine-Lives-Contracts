Nine Lives Contracts
========================
### Preparations
Install dependencies:
```
npm i
npm install -g truffle
npm install -g ganache-cli
```
### Deploy
Open a new Terminal. Compile the contract:
```
truffle compile
```

Start local ethereum blockchain
```
ganache-cli <options>
```

To deploy the smart contract on the development network, run:
```
truffle migrate --network development
```
