#!/usr/bin/env ruby

require 'trollop'
require 'sparkle_formation'
require 'json'
require 'fog'

opts = Trollop::options do
  opt :validate, 'Validate the template only.'
end

cf = Fog::AWS::CloudFormation.new(
  :aws_access_key_id     => ENV['AWS_ACCESS_KEY'],
  :aws_secret_access_key => ENV['AWS_SECRET_KEY']
)

if opts[:validate]
  template = File.open(ARGV[0], 'r').read
else
  template = JSON.pretty_generate(SparkleFormation.compile(ARGV[0]))
  File.open(ARGV[1], 'w').puts template
end

begin
  response = cf.validate_template( "TemplateBody" => template)
rescue Excon::Errors::BadRequest => e
  puts "Validation error: 400 Bad request"
#  puts e.inspect
else
  puts "Template validated successfully."
end
