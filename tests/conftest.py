# @title Testing Framework v1
# @author Kenny Peluso - kennyp.herokuapp.com
# @noticed Much is borrowed: https://github.com/Uniswap/contracts-vyper/blob/master/tests/conftest.py
# @notice Use at your own risk

import os
import pytest
from pytest import raises

from web3 import Web3
from web3.contract import Contract, ImplicitContract
import eth_tester
from eth_tester import EthereumTester, PyEVMBackend

from eth_tester.exceptions import TransactionFailed
from vyper import compiler

'''
# run tests with:             pytest -v tests/
'''

setattr(eth_tester.backends.pyevm.main, 'GENESIS_GAS_LIMIT', 10**9)
setattr(eth_tester.backends.pyevm.main, 'GENESIS_DIFFICULTY', 1)

# Testing Helpers # # # # # # # # # # # # # # # # # # # # 

@pytest.fixture
def tester():
    return EthereumTester(backend=PyEVMBackend())

@pytest.fixture
def w3(tester):
    w3 = Web3(Web3.EthereumTesterProvider(tester))
    w3.eth.setGasPriceStrategy(lambda web3, params: 0)
    w3.eth.defaultAccount = w3.eth.accounts[0]
    return w3

@pytest.fixture
def accts(w3):
    def accts(id):
        return w3.eth.accounts[id]
    return accts

@pytest.fixture
def assert_fail():
    def assert_fail(func):
        with raises(Exception):
            func()
    return assert_fail

def create_contract(w3, path):
    wd = os.path.dirname(os.path.realpath(__file__))
    with open(os.path.join(wd, os.pardir, path)) as f:
        source = f.read()
    bytecode = '0x' + compiler.__compile(source).hex()
    abi = compiler.mk_full_signature(source)
    return w3.eth.contract(abi=abi, bytecode=bytecode)

@pytest.fixture
def pref_uint(w3, accts):
    deploy = create_contract(w3, 'contracts/preferences_basic_uint.vy')
    tx_hash = deploy.constructor(accts(0)).transact()
    tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
    contract = w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=deploy.abi
    )
    return ImplicitContract(contract)

@pytest.fixture
def pref_td(w3, accts):
    deploy = create_contract(w3, 'contracts/preferences_basic_timedelta.vy')
    tx_hash = deploy.constructor(accts(0)).transact()
    tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
    contract = w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=deploy.abi
    )
    return ImplicitContract(contract)

@pytest.fixture
def gov(w3, accts, pref_uint, pref_td):
    deploy = create_contract(w3, 'contracts/governance_basic.vy')
    tx_hash = deploy.constructor(accts(0), pref_uint.address, pref_td.address).transact()
    tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
    contract = w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=deploy.abi
    )
    return ImplicitContract(contract)
