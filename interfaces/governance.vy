# Events

PrefsSet: event({participant: address, enumerated_type: uint256, preferences: address})
IssueRaised: event({sponsor: address, issue: uint256})
BillProposed: event({bill_id: uint256, sponsor: address})
DebateIgnited: event({debate_id: uint256, time_start: uint256(sec, positional), time_end: uint256(sec, positional)})
VotesCast: event({debate_id: uint256, voter: address, votes: uint256, ye: bool})
BillPassed: event({bill_id: uint256, debate_id: uint256, approval: bool})

# Functions

@public
def addPreferences(_dud: address, _type: uint256, _prefs: address) -> bool:
    pass

@public
def addIssue(_dud: address, _type: uint256) -> uint256:
    pass

@public
def propose(_dud: address, _type: uint256, _issue: uint256) -> uint256:
    pass

@public
def debate(_dud: address, _bill: uint256) -> uint256:
    pass

@public
def vote(_dud: address, _debate: uint256, _votes: uint256, _ye: bool) -> uint256:
    pass

@public
def resolve(_debate: uint256) -> bool:
    pass

@constant
@public
def numIssues() -> uint256:
    pass

@constant
@public
def numBills() -> uint256:
    pass

@constant
@public
def numDebates() -> uint256:
    pass
