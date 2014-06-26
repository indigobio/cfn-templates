#!/usr/bin/env ruby

require 'rubygems'
require 'fog'

cf = Fog::AWS::CloudFormation.new(
    :aws_access_key_id     => ENV['AWS_ACCESS_KEY'],
    :aws_secret_access_key => ENV['AWS_SECRET_KEY']
)

template = File.open(ARGV[0], 'rb')
template_contents = template.read

begin
    response = cf.validate_template( "TemplateBody" => template_contents)
rescue Excon::Errors::BadRequest => e
    puts "Validation error: 400 Bad request"
      puts e.inspect
else
    puts "Template validated successfully."
end
