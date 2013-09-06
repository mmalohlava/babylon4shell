#!/usr/bin/python

from random import shuffle

velka=map(chr, range(65, 91))
mala=map(chr, range(97, 123))

shuffle(velka)
shuffle(mala)

r=mala+velka
shuffle(r)
shuffle(r)

print "".join(r)

