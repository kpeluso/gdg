#!/bin/bash

for var in "$@"
do
    # assumes $var is .vy file in contracts/
    vyper contracts/$var.vy > bytecode/$var.txt 
    vyper contracts/$var.vy -f 'abi' > abi/$var.json 
done

# Run with:     chmod u+x
#               ./getCodes.sh governance_basic preferences_basic_timedelta preferences_basic_string preferences_basic_uint preferences_basic_address

# Also useful:  vyper contracts/governance_basic.vy -f 'interface' > interfaces/governance.vy

