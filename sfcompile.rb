#!/usr/bin/env ruby

require 'sparkle_formation'
require 'json'

puts JSON.pretty_generate(
  SparkleFormation.compile(ARGV[0])
)
