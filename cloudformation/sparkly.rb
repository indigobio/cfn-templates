SparkleFormation.new('vpc').load(:nat_ami, :cfn_user).overrides do

  set!('AWSTemplateFormatVersion', '2010-09-09')
  description 'VPC with public and private subnets'

  parameters(:ssh_key_name) do
    type 'String'
  end

  # TODO: figure out how to refer to the nat instance when creating
  # the elastic ip
  dynamic!(:nat_instance, 'indigo', :nat_instance_type => ref!(:nat_instance_type), :ssh_key_name => ref!(:ssh_key_name))
  dynamic!(:elastic_ip, 'indigo_nat', :instance => ref!(:indigo_nat_instance))
end
