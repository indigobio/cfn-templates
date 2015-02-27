#!/usr/bin/env ruby

require 'sparkle_formation'
require 'json'
require 'fog'

cf = Fog::AWS::CloudFormation.new(
  :aws_access_key_id     => ENV['AWS_ACCESS_KEY'],
  :aws_secret_access_key => ENV['AWS_SECRET_KEY']
)

template = JSON.pretty_generate(SparkleFormation.compile(ARGV[0]))
File.open(ARGV[1], 'w').puts template

begin
  response = cf.validate_template( "TemplateBody" => template)
rescue Excon::Errors::BadRequest => e
  puts "Validation error: 400 Bad request"
#  puts e.inspect
else
  puts "Template validated successfully."
end
