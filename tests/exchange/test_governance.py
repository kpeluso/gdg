# @title Testing Generalized Governance and Preferences v1
# @author Kenny Peluso - kennyp.herokuapp.com
# @notice Influenced heavily by Uniswap Vyper contracts
# @notice Use at your own risk

from tests.constants import (
    UINT_ID,
    DEBATE_TIME,
    MIN_REP,
    FOUNDER_REP,
)

def test_gov(w3, assert_fail, pref_uint, pref_td, gov, accts): # 22 assertions
    NEW_ISSUE = FOUNDER_REP + 1
    DEBATE_TIME_VAL = 5
    OTHER_VAL = 2
    FIRST_VAL = 5
    NEW_VAL = 6
    pref_td.setOpinion(DEBATE_TIME, DEBATE_TIME_VAL, transact={'from': accts(0)})
    pref_uint.setOpinion(MIN_REP, OTHER_VAL, transact={'from': accts(0)})
    pref_uint.setOpinion(FOUNDER_REP, OTHER_VAL, transact={'from': accts(0)})
    pref_uint.setOpinion(NEW_ISSUE, FIRST_VAL, transact={'from': accts(0)})
    pref_td.setDelegation(gov.address, transact={'from': accts(0)})
    pref_uint.setDelegation(gov.address, transact={'from': accts(0)})
    assert pref_td.getOpinion(DEBATE_TIME) == DEBATE_TIME_VAL
    assert pref_uint.getOpinion(MIN_REP) == OTHER_VAL
    assert pref_uint.getOpinion(FOUNDER_REP) == OTHER_VAL
    assert pref_uint.getOpinion(NEW_ISSUE) == FIRST_VAL
    assert pref_td.delegation() == gov.address
    assert pref_uint.delegation() == gov.address

    assert gov.getRepOf(accts(0)) == OTHER_VAL
    assert gov.getRepOf(accts(1)) == 0

    gov.addIssue(accts(0), UINT_ID, transact={'from': accts(0)})
    assert gov.numBills() == 4
    assert gov.numIssues() == 4

    assert gov.getLaw_timedelta(DEBATE_TIME) == DEBATE_TIME_VAL
    assert gov.getLaw_uint256(MIN_REP) == OTHER_VAL
    assert gov.getLaw_uint256(FOUNDER_REP) == OTHER_VAL
    assert gov.getLaw_uint256(NEW_ISSUE) == FIRST_VAL

    assert gov.addPreferences(accts(0), UINT_ID, pref_uint.address, transact={'from': accts(0)}) # this line can be commented without consequence

    pref_uint.setOpinion(NEW_ISSUE, NEW_VAL, transact={'from': accts(0)})
    gov.propose(accts(0), UINT_ID, NEW_ISSUE, transact={'from': accts(0)})
    assert gov.numBills() == 5

    gov.debate(accts(0), gov.numBills() - 1, transact={'from': accts(0)})
    assert gov.numDebates() == 1

    gov.vote(accts(0), gov.numDebates() - 1, 2, True, transact={'from': accts(0)})
    assert_fail(lambda: gov.resolve(gov.numDebates() - 1, transact={'from': accts(0)}))
    for _ in range(16): # let at least `DEBATE_TIME_VAL` seconds pass
        assert gov.addIssue(accts(0), UINT_ID, transact={'from': accts(0)})
        assert_fail(lambda: gov.addIssue(accts(0), UINT_ID, transact={'from': accts(1)}))
        assert_fail(lambda: gov.addIssue(accts(1), UINT_ID, transact={'from': accts(1)}))
    gov.resolve(gov.numDebates() - 1, transact={'from': accts(0)})
    assert gov.getLaw_uint256(NEW_ISSUE) == NEW_VAL
