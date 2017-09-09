#!/bin/bash

IP=`hostname -i| tr ' ' '\n' | tail -n 2 | head -n 1 | tr -d '\n'`
PORT="8081"
node verify.js "http://${IP}:${PORT}" ../src/main/resources  3>&1 1>&2 2>&3 3>- | ./connect_smartwatch.sh
