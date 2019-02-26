# GDG: Generalized Decentralized Governance

Create any governance structure (even centralized governance!) using the methodology outlined here.

## Installation

1. Install [Python 3](https://www.python.org/download/releases/3.0/)
2. Clone `vyper-contracts`
```
$ git clone https://github.com/uniswap/contracts-vyper
$ cd vyper-contracts
```
3. Set up virtual environment
```
$ pip3 install virtualenv
$ virtualenv -p python3 env
$ source env/bin/activate
```

3) Install dependencies
```
pip install -r requirements.txt
```

4) Run tests
```
$ pytest -v tests/
```

## Useful

Use `getCode.sh` to quickly generate bytecode and abi if you wish to fork and edit any of the contracts.

## License

MIT
