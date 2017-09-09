#!/bin/bash

# record input and output it to stderr in case of errors
head -n 4 | tee code.txt 3>&1 1>&2 2>&3 3>-
# xterm -e 'xxd code.txt;sleep 100'
# adb kill-server
# sudo adb start-server
# adb forward tcp:9090 tcp:8080
echo >> code.txt                # add extra newline
cat code.txt | nc localhost 9090
