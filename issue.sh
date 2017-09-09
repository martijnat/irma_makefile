#!/bin/bash

IP=`hostname -i | tr ' ' '\n' | tail -n 2 | head -n 1 | tr -d '\n'`
PORT="8081"

# The trick here is that we purposfully output the smartwatch content to stderr
node issue.js "http://${IP}:${PORT}" 3>&1 1>&2 2>&3 3>- | ./connect_smartwatch.sh
