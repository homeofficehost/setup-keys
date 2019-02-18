#!/bin/bash

if [ $# -ne 2 ] ; then
  echo "Usage: ssh-add-pass keyfile passphrase"
  exit 1
fi

pass=$2

expect << EOF
  spawn /usr/bin/ssh-add -K $1
  expect "Enter passphrase"
  send "${pass}\r"
  expect eof
EOF