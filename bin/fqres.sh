#!/bin/bash

grep -A 1 "@M0" $1 | grep -v "@M0" | grep -v "\-\-" | awk 'BEGIN { sum=0; } { sum+=length($1); } END { print sum; }'

