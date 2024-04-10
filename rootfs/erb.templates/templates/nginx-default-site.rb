#!/usr/bin/env ruby

require "erb"

FILE_PATH = "/etc/nginx/sites-enabled/default".freeze

RAILS_ENV = ENV.fetch("RAILS_ENV", "production")

FRIENDLY_ERROR_PAGES = ENV.fetch(
  "PASSENGER_FRIENDLY_ERROR_PAGES",
  RAILS_ENV == "production" ? "off" : "on"
)

WITH_ACTION_CABLE = !ENV.fetch("NO_ACTION_CABLE", false)

CABLE_PASSENGER_FORCE_MAX_CONCURRENT_REQUESTS_PER_PROCESS = ENV.fetch(
  "CABLE_PASSENGER_FORCE_MAX_CONCURRENT_REQUESTS_PER_PROCESS",
  1000
).to_i

PASSENGER_MAX_REQUESTS = ENV.fetch(
  "PASSENGER_MAX_REQUESTS",
  3_000
).to_i

TEMPLATE = <<~ERB.freeze
    server {
      listen 0.0.0.0:80 default_server;
      server_name _;

      root /home/webapp/webapp/current/public;
      client_max_body_size 0;
      passenger_user webapp;
      passenger_group webapp;


      location / {
          passenger_enabled on;
          passenger_user webapp;
          passenger_app_group_name rails_webapp;
          passenger_preload_bundler on;
          passenger_app_env <%= RAILS_ENV %>;
          passenger_friendly_error_pages <%= FRIENDLY_ERROR_PAGES %>;
          passenger_max_requests <%= PASSENGER_MAX_REQUESTS %>;
      }

      <% if WITH_ACTION_CABLE %>
      location ~ ^/cable/? {
          passenger_enabled on;
          passenger_user webapp;
          passenger_app_group_name rails_action_cable;
          passenger_preload_bundler on;
          passenger_app_env <%= RAILS_ENV %>;
          passenger_friendly_error_pages <%= FRIENDLY_ERROR_PAGES %>;
          passenger_max_requests <%= PASSENGER_MAX_REQUESTS %>;
          passenger_env_var RAILS_CABLE_PROCESS true;
          passenger_force_max_concurrent_requests_per_process <%= CABLE_PASSENGER_FORCE_MAX_CONCURRENT_REQUESTS_PER_PROCESS %>;
      }
      <% end %>

      location ~ ^/(assets|fonts|system)/|favicon.ico|robots.txt {
          gzip on;
          gzip_static on;
          brotli on;
          brotli_static on;
          expires max;
          add_header Cache-Control public;
      }

      passenger_env_var HTTP_X_FORWARDED_PROTO https;
      server_tokens off;
      more_clear_headers  'Server' 'X-Powered-By' 'X-Runtime' 'X-Request-Id' 'X-Rack-Cache';
  }
ERB

File.write(FILE_PATH, ERB.new(TEMPLATE).result)
