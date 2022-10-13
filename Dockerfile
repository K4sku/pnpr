FROM ipepe/pnpr:v2-staging-ruby-2.7.2

# Install nodejs
RUN n 12.19.0 && npm install -g npm && npm install -g yarn