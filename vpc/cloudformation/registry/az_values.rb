case ENV['AWS_DEFAULT_REGION']
  when 'us-west-1'
    zones = ['us-west-1a', 'us-west-1b', 'us-west-1c']
  when 'us-west-2'
    zones = ['us-west-2a', 'us-west-2b', 'us-west-2c']
  else
    zones = ['us-east-1a', 'us-east-1c', 'us-east-1d', 'us-east-1e']
end

SfnRegistry.register(:az_values) do
  allowed_values zones
end

SfnRegistry.register(:default_az) do
  default zones[0]
end
