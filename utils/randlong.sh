#!/bin/bash
cat /dev/urandom | tr -dc '0-9a-f' | fold -w 16| head -n 1
