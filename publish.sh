#!/bin/bash

set -e

RUBY_VERSIONS=(2.3.8 2.4.10 2.5.9 2.6.10 2.7.2 2.7.5 2.7.6 3.0.4 3.1.2)

for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
  echo "Building ruby ipepe/pnpr:v2-staging-ruby-$RUBY_VERSION"
  docker build . -t "ipepe/pnpr:v2-staging-ruby-$RUBY_VERSION" --build-arg RUBY_VERSION=$RUBY_VERSION
  docker push "ipepe/pnpr:v2-staging-ruby-$RUBY_VERSION"

  docker build . -t "ipepe/pnpr:v2-production-ruby-$RUBY_VERSION" \
            --build-arg RUBY_VERSION=$RUBY_VERSION \
            --build-arg RAILS_ENV=production \
            --build-arg NODE_ENV=production \
            --build-arg FRIENDLY_ERROR_PAGES=off \
            --build-arg WITH_SUDO=false
  docker push "ipepe/pnpr:v2-production-ruby-$RUBY_VERSION"
done



