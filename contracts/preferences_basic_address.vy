# @title Vyper Preferences Store - Basic Implementation for address v1
# @author Kenny Peluso - kennyp.herokuapp.com
# @notice Use at your own risk
# @notice This contract allows you to store your preferences for a particualr issue
# @notice Make one of these contracts per type in range self.issues in governance contract

# Globals
inDebate: public(bool)
owner: public(address)
delegation: public(address)
opinions: map(uint256, address)

# Public Functions

@public
def __init__(_owner: address):
    self.owner = _owner

@public
def isInDebate(_status: bool) -> bool:
    assert msg.sender == self.delegation
    self.inDebate = _status
    return _status

@public
def setDelegation(_gov: address) -> bool:
    assert self.owner == msg.sender
    assert not self.inDebate
    self.delegation = _gov
    return True

@public
def setOpinion(_issue: uint256, _opinion: address) -> bool:
    assert self.owner == msg.sender
    assert not self.inDebate
    self.opinions[_issue] = _opinion
    return True

@public
@constant
def getOpinion(_issue: uint256) -> address:
    return self.opinions[_issue]
