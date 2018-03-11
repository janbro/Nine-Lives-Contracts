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

### Testing
Tests framework is [mocha](https://mochajs.org/). Run tests with:
```
truffle test
``` 

### License

Copyright (c) 2018 Alejandro Munoz-McDonald

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
