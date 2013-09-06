#!/bin/bash
# gen-tests.sh -- created 2011-01-10, <+NAME+>
# @Last Change: 24-Dez-2004.
# @Revision:    0.0
MAX=10000000
seq $MAX | shuf > tests/test03.in
echo >> tests/test03.in
seq $MAX >  tests/test03.out

# vi: 
