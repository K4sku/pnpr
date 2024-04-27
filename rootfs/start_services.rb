#!/usr/bin/env ruby

WITHOUT_SERVICE_NAMES = ENV["WITHOUT_SERVICE_NAMES"].to_s.split(",").map(&:strip)

DEFAULT_SERVICE_NAMES = ARGV.map(&:strip)

SERVICE_NAMES = (
  DEFAULT_SERVICE_NAMES - WITHOUT_SERVICE_NAMES
).map(&:to_sym).freeze

puts "SERVICE_NAMES: #{SERVICE_NAMES.join(", ")}"
puts "WITHOUT_SERVICE_NAMES: #{WITHOUT_SERVICE_NAMES.join(", ")}"
puts "DEFAULT_SERVICE_NAMES: #{DEFAULT_SERVICE_NAMES.join(", ")}"

SERVICE_NAMES.each do |service_name|
  system("service #{service_name} start")
end

if SERVICE_NAMES.include?(:"foremand-supervisor")
  system("foremand start")
end
