#!/usr/bin/env ruby
ruby_version = "3.2.3"
node_version = "20.12.1"

image_tag = "prod-u20.04-r#{ruby_version}_jema_yjit-n#{node_version}"
image_name = "kasku/pnpr:#{image_tag}"
env_level = "production"
friendly_error_pages =
  if env_level == "production"
    "off"
  else
    "on"
  end
puts "Building #{image_name}"
`docker build . --tag "#{image_name}" \
        --build-arg RUBY_VERSION=#{ruby_version} \
        --build-arg RAILS_ENV=#{env_level} \
        --build-arg NODE_ENV=#{env_level} \
        --build-arg FRIENDLY_ERROR_PAGES=#{friendly_error_pages}`
