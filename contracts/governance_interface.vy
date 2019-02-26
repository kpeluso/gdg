# @title Vyper Generalized Governance - Interface v1
# @author Kenny Peluso - kennyp.herokuapp.com
# @notice Use at your own risk
# @notice This contract outlines a generalized framework for governacne in Vyper

# Events
BillProposed: event({bill_id: indexed(uint256), sponsor: indexed(address)})
BillStatusChanged: event({bill_id: indexed(uint256), approval: indexed(bool)})
DebateIgnited: event({debate_id: indexed(uint256), time_start: indexed(timestamp), time_end: indexed(timestamp)})

# Globals
numBills: public(uint256)
numDebates: public(uint256)

# Public Functions

#
# ASK NICK ABOUT HAVING VARIABLE PARAMETERS IN HERE:
# (OR IF THAT GOES IN LIKE eip DESCRIPTION?)
#
@public
def propose() -> uint256:
    """
    @dev MUST accept data proposed to modify contested field
    @dev MUST have corresponding event per type of proposal 
    """
    pass

@public
def debate(_bill: uint256) -> uint256:
    pass
