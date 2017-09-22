#!/bin/bash

# record input and output it to stderr in case of errors
head -n 4 | tee code.txt 3>&1 1>&2 2>&3 3>-
echo >> code.txt                # add extra newline
cat code.txt | nc localhost 9090
