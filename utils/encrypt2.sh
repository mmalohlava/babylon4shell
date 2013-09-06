#!/bin/bash
# encrypt.sh -- created 2013-04-11, <+NAME+>
# @Last Change: 24-Dez-2004.
# @Revision:    0.0

APERM=$(./randa.py)
NPERM=$(./randn.py)
cat big_template.dat | tr 'a-zA-Z0-9' "${APERM}${NPERM}" | shuf


# vi: 
