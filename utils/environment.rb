ENV['org']                ||= 'indigo'
ENV['environment']        ||= 'dr'
ENV['AWS_DEFAULT_REGION'] ||= 'us-east-1'
pfx                         = "#{ENV['org']}-#{ENV['environment']}-#{ENV['AWS_DEFAULT_REGION']}"

ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['AWS_DEFAULT_REGION']}-terminated-instances"
ENV['vpc_name']           ||= "#{pfx}-vpc"
ENV['cert_name']          ||= "#{pfx}-cert"
ENV['public_domain']      ||= 'ascentrecovery.net'
ENV['private_domain']     ||= "#{ENV['environment']}.#{ENV['org']}"

ENV['snapshots']          ||= ''
ENV['backup_id']          ||= ''

ENV['autoscale']          ||= 'false'