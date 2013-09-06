#!/usr/bin/python

from random import shuffle

num=map(str, range(0, 10))

shuffle(num)

print "".join(num)

