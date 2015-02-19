ENV['instances'] ||= '1'
ENV['region'] ||= 'us-east-1'

s = SparkleFormation.new('vpc')

%w(trusty_ami
   cfn_user
   chef_validator_key_bucket).each { |c| s.load(c.to_sym)}

s.overrides do

  set!('AWSTemplateFormatVersion', '2010-09-09')
  description "let's get sparkly"

  parameters(:ssh_key_pair) do
    description 'Amazon EC2 key pair'
    type 'AWS::EC2::KeyPair::KeyName'
  end

  # TODO: use the set! helper to carry the instance name forward to the ebs volume attachment.
  dynamic!(:security_group, 'indigo')
  dynamic!(:sg_ingress_from_subnet, 'indigo', :target => :indigo_security_group)
  dynamic!(:launch_config, 'indigo', :security_groups => [ :indigo_security_group ], :volume_count => 2, :volume_size => 10)
  dynamic!(:auto_scaling_group, 'indigo', :launch_config => :indigo_launch_config, :desired_capacity => 2, :max_size => 2)

  #1.upto ENV['instances'].to_i do |i|
  #  dynamic!(:bootstrapped_instance, "indigo#{i}", :no_subnet => true, :security_groups => [ :indigo_security_group ])
  #end
  #dynamic!(:ebs_volume, 'xvdi1', :instance => :indigo_instance, :size => '10', :volume_type => 'gp2')
  #dynamic!(:elastic_ip, 'indigo_nat', :instance => ref!(:indigo_bootstrap_instance))
end



