#!/bin/bash

set -e

echo "Currently running file: $0"
source /home/webapp/.bashrc

cd /home/webapp/webapp/current

/home/webapp/.rbenv/shims/bundle install --without development test --deployment --jobs 8
