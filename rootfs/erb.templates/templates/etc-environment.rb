#!/usr/bin/env ruby

require "erb"

FILE_PATH = "/etc/environment".freeze

parsed_data = DATA.gets.split("\n").select do |line|
  !line.nil? && !line.empty? && !line.strip.empty?
end.map do |line|
  line.split("=")
end.to_h

ENV_RUBY_VERSION = ENV.fetch("RUBY_VERSION", parsed_data["RUBY_VERSION"]) || "3.2.3"
RAILS_ENV = ENV.fetch("RAILS_ENV", parsed_data["RAILS_ENV"] || "production")
NODE_ENV = ENV.fetch("NODE_ENV", parsed_data["NODE_ENV"] || "production")
FRIENDLY_ERROR_PAGES = ENV.fetch("PASSENGER_FRIENDLY_ERROR_PAGES",
                                 parsed_data["FRIENDLY_ERROR_PAGES"]) || "off"

TEMPLATE = <<~ERB.freeze
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
  RUBY_VERSION=<%= RUBY_VERSION %>
  RAILS_ENV=<%= RAILS_ENV %>
  NODE_ENV=<%= NODE_ENV %>
  FRIENDLY_ERROR_PAGES=<%= FRIENDLY_ERROR_PAGES %>
ERB

DATA

File.write(FILE_PATH, ERB.new(TEMPLATE).result)

# below will be interpolated "build" variables
__END__
