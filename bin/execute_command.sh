#!/bin/bash

#   cd /var/atlassian/application-data/bitbucket_home/shared/data/repositories/
find . -type d -maxdepth 1 | while read d; do
   pushd $d
   git log --all --date=raw --pretty=format:'%h,%ae,%at,$d' >> /tmp/commits.out
   popd
done
