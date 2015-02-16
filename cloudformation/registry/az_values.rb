ENV['region'] ||= 'us-east-1'

case ENV['region']
  when 'us-west-1'
    zones = ['us-west-1a', 'us-west-1b', 'us-west-1c']
  when 'us-west-2'
    zones = ['us-west-2a', 'us-west-2b', 'us-west-2c']
  when 'eu-west-1'
    zones = ['eu-west-1a', 'eu-west-1b', 'eu-west-1c']
  when 'eu-central-1'
    zones = ['eu-central-1a', 'eu-central-1b`']
  else
    zones = ['us-east-1a', 'us-east-1b', 'us-east-1c', 'us-east-1d', 'us-east-1e']
end

SparkleFormation::Registry.register(:az_values) do
  allowed_values zones
end

SparkleFormation::Registry.register(:default_az) do
  default zones[0]
end