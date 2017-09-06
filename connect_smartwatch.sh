#!/bin/bash

# record input and output it to stderr in case of errors
head -n 4 | tee code.txt 3>&1 1>&2 2>&3 3>-
xterm -fullscreen -e 'qrcode-terminal "$(cat code.txt)";sleep 10'
