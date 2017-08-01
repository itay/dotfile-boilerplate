#!/bin/bash

NUM_BRANCHES=$(wc -l /tmp/branches.txt | awk '{gsub(/^ +| +$/,"")}1')

idx=0
while read p; do
  idx=$[$idx+1]
  echo "Deleting branch $idx/$NUM_BRANCHES: $p"
  git push origin --delete $p
done < /tmp/branches.txt
