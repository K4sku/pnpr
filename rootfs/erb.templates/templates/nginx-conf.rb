#!/usr/bin/env ruby

require "erb"

FILE_PATH = "/etc/nginx/nginx.conf".freeze

PASSENGER_MAX_REQUEST_QUEUE_SIZE = ENV.fetch(
  "PASSENGER_MAX_REQUEST_QUEUE_SIZE",
  1000
).to_i

PASSENGER_MAX_POOL_SIZE = ENV.fetch(
  "PASSENGER_MAX_POOL_SIZE",
  60
).to_i

TEMPLATE = <<~ERB.freeze
  user www-data;
  worker_processes auto;
  pid /run/nginx.pid;
  include /etc/nginx/modules-enabled/*.conf;

  events {
      worker_connections 768;
      # multi_accept on;
  }

  http {

  	##
  	# Basic Settings
  	##

  	sendfile on;
  	tcp_nopush on;
  	tcp_nodelay on;
  	keepalive_timeout 65;
  	types_hash_max_size 2048;
  	# server_tokens off;

  	# server_names_hash_bucket_size 64;
  	# server_name_in_redirect off;

  	include /etc/nginx/mime.types;
  	default_type application/octet-stream;

  	##
  	# Logging Settings
  	##

  	access_log /var/log/nginx/access.log;
  	error_log /var/log/nginx/error.log;

  	##
  	# Gzip Settings
  	##

  	gzip on;
  	gzip_disable "msie6";

  	# gzip_vary on;
  	# gzip_proxied any;
  	# gzip_comp_level 6;
  	# gzip_buffers 16 8k;
  	# gzip_http_version 1.1;
  	# gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    ##
    # Brotli Settings
    # https://github.com/google/ngx_brotli?tab=readme-ov-file#configuration-directives
    ##

    brotli on;
    # brotli_static on;
    # brotli_buffers 32 4k;
    # brotli_comp_level 6;
    # brotli_window 512k;
    # brotli_min_length 20;

    # File types to compress
    brotli_types application/atom+xml application/javascript application/json application/rss+xml
                 application/vnd.ms-fontobject application/x-font-opentype application/x-font-truetype
                 application/x-font-ttf application/x-javascript application/xhtml+xml application/xml
                 font/eot font/opentype font/otf font/truetype image/svg+xml image/vnd.microsoft.icon
                 image/x-icon image/x-win-bitmap text/css text/javascript text/plain text/xml;

  	##
  	# nginx-naxsi config
  	##
  	# Uncomment it if you installed nginx-naxsi
  	##

  	# include /etc/nginx/naxsi_core.rules;

  	##
  	# Phusion Passenger config
  	##

  	passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
  	passenger_ruby /home/webapp/.rbenv/shims/ruby;

  	passenger_max_preloader_idle_time 0;
    passenger_pre_start https://localhost/;
    passenger_pre_start https://localhost/cable;

    passenger_max_request_queue_size <%= PASSENGER_MAX_REQUEST_QUEUE_SIZE %>;
    passenger_max_pool_size <%= PASSENGER_MAX_POOL_SIZE %>;

  	##
  	# Virtual Host Configs
  	##

  	include /etc/nginx/conf.d/*.conf;
  	include /etc/nginx/sites-enabled/*;
  }
ERB

File.write(FILE_PATH, ERB.new(TEMPLATE).result)
