# Available in ~/envs/xxx
ENV['org']                ||= 'indigo'
ENV['environment']        ||= 'dr'
ENV['AWS_DEFAULT_REGION'] ||= 'us-east-1'

# Unused.
pfx                         = "#{ENV['org']}-#{ENV['environment']}-#{ENV['AWS_DEFAULT_REGION']}"

# Available in https://github.com/gswallow/sparkle-pack-aws-my-sns-topics
ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['AWS_DEFAULT_REGION']}-terminated-instances"

ENV['vpc_name']           ||= "#{pfx}-vpc"

# Unused
ENV['cert_name']          ||= "#{pfx}-cert"

# Available in utils/common.sh
ENV['public_domain']      ||= 'ascentrecovery.net'
ENV['private_domain']     ||= "#{ENV['environment']}.#{ENV['org']}"

# Available in https://github.com/gswallow/sparkle-pack-aws-my-snapshots
ENV['snapshots']          ||= ''
ENV['backup_id']          ||= ''

# Not used
ENV['autoscale']          ||= 'false'
