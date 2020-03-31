#!/bin/bash

read -r IN

if [ "$1" = "fail" ] || [ "$IN" = "this should fail" ]; then
    exit 1
else
    echo "${IN}" | sed s/in/out/
fi
