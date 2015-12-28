#!/usr/bin/env ruby

require 'trollop'
require 'sparkle_formation'
require 'json'
require 'fog'

opts = Trollop::options do
  opt :validate, 'Validate the template only.'
  opt :pretty, 'Generate pretty cloudformation templates.'
end

cf = Fog::AWS::CloudFormation.new(
  :aws_access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
  :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
)

unless opts[:validate]
  if opts[:pretty]
    template = JSON.pretty_generate(SparkleFormation.compile(ARGV[0]))
  else
    template = JSON.generate(SparkleFormation.compile(ARGV[0]))
  end
  File.open(ARGV[1], 'w').puts template
end

if opts[:validate]
  template = File.open(ARGV[0], 'r').read
end

begin
  cf.validate_template( "TemplateBody" => template)
rescue Excon::Errors::BadRequest => e
  puts "Validation error: 400 Bad request."
  exit 1
end

puts "Template validated successfully."
