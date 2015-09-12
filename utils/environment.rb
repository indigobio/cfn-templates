ENV['org']                ||= 'indigo'
ENV['environment']        ||= 'dr'
ENV['region']             ||= 'us-east-1'
pfx                         = "#{ENV['org']}-#{ENV['environment']}-#{ENV['region']}"

ENV['notification_topic'] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"
ENV['vpc_name']           ||= "#{pfx}-vpc"
ENV['cert_name']          ||= "#{pfx}-cert"
ENV['lb_name']            ||= "#{pfx}-public-elb"
ENV['public_domain']      ||= 'ascentrecovery.net'

ENV['snapshots']          ||= ''
ENV['backup_id']          ||= ''

ENV['autoscale']          ||= 'false'