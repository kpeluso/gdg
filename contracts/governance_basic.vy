# @title Vyper Generalized Governance - Basic Implementation v1
# @author Kenny Peluso - kennyp.herokuapp.com
# @notice Use at your own risk
# @notice This contract allows you to debate debate length and the "reputation" of whitelisted members

# Structs

struct Bill:
    sponsor: address        # who created the bill
    enumerated_type: uint256    # enumerated type id
    issue: uint256          # index of parameter whose value is being questioned

struct Debate:
    bill_id: uint256        # bill to be debated
    time_start: timestamp   # start time of this debate's time window
    time_end: timestamp     # end time of this debate's time window
    ye: uint256             # cumulative votes for "yes, implement this change"
    ne: uint256             # cumulative votes for "no, don't implement this change"

# Interfaces

contract Preferences_uint():
    def getOpinion(_issue: uint256) -> uint256: constant
    def isInDebate(_status: bool) -> bool: modifying

contract Preferences_timedelta():
    def getOpinion(_issue: uint256) -> timedelta: constant
    def isInDebate(_status: bool) -> bool: modifying

# Events
PrefsSet: event({participant: indexed(address), enumerated_type: indexed(uint256), preferences: indexed(address)})
IssueRaised: event({sponsor: indexed(address), issue: indexed(uint256)})
BillProposed: event({bill_id: indexed(uint256), sponsor: indexed(address)})
DebateIgnited: event({debate_id: indexed(uint256), time_start: indexed(timestamp), time_end: indexed(timestamp)})
VotesCast: event({debate_id: indexed(uint256), voter: indexed(address), votes: uint256, ye: indexed(bool)})
BillPassed: event({bill_id: indexed(uint256), debate_id: indexed(uint256), approval: indexed(bool)})

# Globals
UINT_ID: constant(uint256) = 0          # enumerated uint256 id
TD_ID: constant(uint256) = 1            # enumerated timedelta id
TIMEDELTA_IDX: constant(uint256) = 0    # issue id for debate length
MIN_DEBATE_REP_IDX: constant(uint256) = 1   # issue id for minimum reputation necessary to debate
FOUNDER_REP_IDX: constant(uint256) = 2  # issue id for reputation of founding member
whitelist: map(address, uint256)        # sender -> issue_id
bills: map(uint256, Bill)               # bill_id -> bill_struct
debates: map(uint256, Debate)           # debate_id -> debate_struct
votes: map(address, map(uint256, uint256))  # whitelisted_member -> debate_id -> total_votes_cast_in_debate_id
numIssues: public(uint256)              # enumerates all issues
numBills: public(uint256)               # enumerates all bills
numDebates: public(uint256)             # enumerates all debates
prefs: map(uint256, map(address, address))  # enumerated_type_id -> sender -> preferences_contract
precedent: map(uint256, uint256)        # issue_id -> latest_approved_debate_id
law: map(uint256, uint256)              # issue_id -> bill_id
approvals: map(address, address)

# Private Functions

@private
def _lockPrefs(_dud: address, _lock: bool) -> bool:
    """
    @notice Prevents/Allows member from changing their preferences as a debate over their opinions is raged
    @param _dud Address of member
    @param _lock True for "lock this address", False for "don't lock this address's preferences"
    @return _lock
    """
    Preferences_uint(self.prefs[UINT_ID][_dud]).isInDebate(_lock)
    Preferences_timedelta(self.prefs[TD_ID][_dud]).isInDebate(_lock)
    return _lock

# Public Functions

@public
@constant
def getLaw_uint256(_issue: uint256) -> uint256:
    """
    @notice Get accepted truth
    @param _issue Id issue
    @return Accepted value for issue
    """
    return Preferences_uint(self.prefs[UINT_ID][self.bills[self.law[_issue]].sponsor]).getOpinion(_issue)

@public
@constant
def getLaw_timedelta(_issue: uint256) -> timedelta:
    """
    @notice Get issue id from debate id
    @param _issue Id issue
    @return Accepted value for issue
    """
    return Preferences_timedelta(self.prefs[TD_ID][self.bills[self.law[_issue]].sponsor]).getOpinion(_issue)

@public
@constant
def getRepOf(_dud: address) -> uint256:
    """
    @notice Get reputation of an address
    @param _dud Address of user/contract in question
    @return Rep of user/contract in question
    """
    return self.getLaw_uint256(self.whitelist[_dud])

@public
@constant
def getIssueFromDebate(_debate: uint256) -> uint256:
    """
    @notice Get issue id from debate id
    @param _debate Id of debate
    @return Issue id
    """
    return self.bills[self.debates[_debate].bill_id].issue

@public
def __init__(founder: address, founder_prefs_uint: address, founder_prefs_td: address):
    self.bills[TIMEDELTA_IDX] = Bill({sponsor: founder, enumerated_type: TD_ID, issue: TIMEDELTA_IDX})
    self.bills[MIN_DEBATE_REP_IDX] = Bill({sponsor: founder, enumerated_type: UINT_ID, issue: MIN_DEBATE_REP_IDX})
    self.bills[FOUNDER_REP_IDX] = Bill({sponsor: founder, enumerated_type: UINT_ID, issue: FOUNDER_REP_IDX})
    self.law[TIMEDELTA_IDX] = TIMEDELTA_IDX
    self.law[MIN_DEBATE_REP_IDX] = MIN_DEBATE_REP_IDX
    self.law[FOUNDER_REP_IDX] = FOUNDER_REP_IDX
    self.numIssues = 3
    self.numBills = 3
    log.BillPassed(0, 0, True)
    log.BillPassed(1, 0, True)
    log.BillPassed(2, 0, True)
    self.whitelist[founder] = FOUNDER_REP_IDX
    self.prefs[UINT_ID][founder] = founder_prefs_uint
    self.prefs[TD_ID][founder] = founder_prefs_td

@public
def addPreferences(_dud: address, _type: uint256, _prefs: address) -> bool:
    """
    @notice Add a reference to the preferences of a sender
    @param _dud Address of member
    @param _type Enumerated type id
    @param _prefs Address of sender preferences
    @return True for success else False
    """
    assert msg.sender == _dud or self.approvals[_dud] == msg.sender
    assert _prefs != ZERO_ADDRESS
    self.prefs[_type][_dud] = _prefs
    log.PrefsSet(_dud, _type, _prefs)
    return True

@public
def addIssue(_dud: address, _type: uint256) -> uint256:
    """
    @notice Raise an issue
    @dev Sponsor MUST be whitelisted
    @param _dud Address of member
    @param _type Enumerated type id
    @return Id of minted issue
    """
    assert msg.sender == _dud or self.approvals[_dud] == msg.sender
    assert self.getRepOf(_dud) >= self.getLaw_uint256(MIN_DEBATE_REP_IDX)
    self.bills[self.numBills] = Bill({sponsor: _dud, enumerated_type: _type, issue: self.numIssues})
    self.law[self.numIssues] = self.numBills
    log.BillPassed(self.numBills, 0, True)
    self.numBills += 1
    log.IssueRaised(_dud, self.numIssues)
    self.numIssues += 1
    return self.numIssues - 1

@public
def propose(_dud: address, _type: uint256, _issue: uint256) -> uint256:
    """
    @notice Propose a bill
    @dev Sponsor MUST be whitelisted
    @param _dud Address of member
    @param _issue Id of a parameter for which a new value is being proposed
    @return Id of minted bill
    """
    assert msg.sender == _dud or self.approvals[_dud] == msg.sender
    assert self.getRepOf(_dud) >= self.getLaw_uint256(MIN_DEBATE_REP_IDX)
    assert self.prefs[_type][_dud] != ZERO_ADDRESS
    _pref: uint256 = Preferences_uint(self.prefs[_type][_dud]).getOpinion(_issue)
    self.bills[self.numBills] = Bill({sponsor: _dud, enumerated_type: _type, issue: _issue})
    log.BillProposed(self.numBills, _dud)
    self.numBills += 1
    return self.numBills - 1

@public
def debate(_dud: address, _bill: uint256) -> uint256:
    """
    @notice Initiates a debate toward the approval of a bill or lack thereof
    @dev Sponsor MUST be whitelisted
    @param _dud Address of member
    @param _bill Id of bill to be debated
    @return Id of minted debate
    """
    assert msg.sender == _dud or self.approvals[_dud] == msg.sender
    assert self.getRepOf(_dud) >= self.getLaw_uint256(MIN_DEBATE_REP_IDX)
    self._lockPrefs(self.bills[_bill].sponsor, True)
    self.debates[self.numDebates] = Debate({bill_id: _bill, time_start: block.timestamp, time_end: block.timestamp + self.getLaw_timedelta(TIMEDELTA_IDX), ye: 0, ne: 0})
    log.DebateIgnited(self.numDebates, block.timestamp, block.timestamp + self.getLaw_timedelta(TIMEDELTA_IDX))
    self.numDebates += 1
    return self.numDebates - 1

@public
def vote(_dud: address, _debate: uint256, _votes: uint256, _ye: bool) -> uint256:
    """
    @notice Propose a bill
    @dev Sponsor MUST be whitelisted
    @param _dud Address of member
    @param _debate Id of debate in which votes will be cast
    @param _votes Number of votes to be cast
    @param _ye True if votes are for 'yes' else False
    @return Votes remaining for this debate for this voter
    """
    assert msg.sender == _dud or self.approvals[_dud] == msg.sender
    assert self.votes[_dud][_debate] <= self.getRepOf(_dud)
    assert block.timestamp > self.debates[_debate].time_start
    assert block.timestamp < self.debates[_debate].time_end
    self.votes[_dud][_debate] += _votes
    if _ye:
        self.debates[_debate].ye += _votes
    else:
        self.debates[_debate].ne += _votes
    log.VotesCast(_debate, _dud, _votes, _ye)
    return self.getRepOf(_dud) - self.votes[_dud][_debate]

@public
def resolve(_debate: uint256) -> bool:
    """
    @notice End a debate and decide outcome for bill
    @param _debate Id of debate in which votes will be cast
    @return True if bill approved else False
    """
    assert block.timestamp > self.debates[_debate].time_end
    self.precedent[self.getIssueFromDebate(_debate)] = _debate
    self.law[self.getIssueFromDebate(_debate)] = self.debates[_debate].bill_id
    self._lockPrefs(self.bills[self.debates[_debate].bill_id].sponsor, False)
    log.BillPassed(self.debates[_debate].bill_id, _debate, self.debates[_debate].ye > self.debates[_debate].ne)
    return self.debates[_debate].ye > self.debates[_debate].ne
