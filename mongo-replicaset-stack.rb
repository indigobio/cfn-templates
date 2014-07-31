#!/usr/bin/env ruby

require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/spotprice'
require 'cloudformation-ruby-dsl/table'

def getUniqueAZ(set)
  loop do
    az = rand(1..5)
    return az unless set.find_index(az)
  end
end

template do

  value :AWSTemplateFormatVersion => '2010-09-09'

  value :Description => 'This template creates a three-node MongoDB replicaset using Chef to run the mongo_server role'

  parameter 'KeyName',
            :Description => 'Name of an existing EC2 KeyPair to enable SSH access to the server',
            :Type => 'String',
            :Default => 'indigo-biosystems',
            :MinLength => '1',
            :MaxLength => '255',
            :AllowedPattern => '[\\x20-\\x7E]*',
            :ConstraintDescription => 'can contain only ASCII characters.'

  parameter 'InstanceType',
            :Type => 'String',
            :Default => 'm3.medium',
            :AllowedValues => [
                'm3.medium',
                'm3.large',
                'm3.xlarge',
                'm3.2xlarge',
                'r3.large',
                'r3.xlarge',
                'r3.2xlarge',
                'r3.4xlarge',
                'r3.8xlarge',
                'c3.large',
            ],
            :Description => 'EC2 instance type (e.g. m3.large, m3.xlarge, r3.xlarge)',
            :ConstraintDescription => 'must be a valid EC2 instance type.'

  parameter 'VolumeSize',
            :Description => 'Volume size for each EBS volume',
            :Type => 'Number',
            :Default => '10'

  parameter 'SSHLocation',
            :Description => 'The IP address range that can be used to SSH to the EC2 instances',
            :Type => 'String',
            :MinLength => '9',
            :MaxLength => '18',
            :Default => '0.0.0.0/0',
            :AllowedPattern => '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})',
            :ConstraintDescription => 'must be a valid IP CIDR range of the form x.x.x.x/x.'

  parameter 'ChefServerURL',
            :Description => 'URL of Chef Server',
            :Type => 'String',
            :Default => 'https://api.opscode.com/organizations/product_dev',
            :AllowedPattern => '[\\x20-\\x7E]*',
            :ConstraintDescription => 'can only contain ASCII characters'

  parameter 'ChefServerPrivateKeyBucket',
            :Description => 'S3 bucket containing validation key for Chef Server',
            :Type => 'String',
            :Default => 'gswallow-indigo',
            :AllowedPattern => '[\\x20-\\x7E]*',
            :ConstraintDescription => 'can only contain ASCII characters'

  parameter 'ChefValidationClientUsername',
            :Description => 'Chef validation client username',
            :Type => 'String',
            :Default => 'product_dev-validator',
            :AllowedPattern => '[\\x20-\\x7E]*',
            :ConstraintDescription => 'can only contain ASCII characters'

  parameter 'ChefEnvironment',
            :Description => 'Chef Environment',
            :Type => 'String',
            :Default => 'dr',
            :AllowedPattern => '[\\x20-\\x7E]*',
            :ConstraintDescription => 'can only contain ASCII characters'

  parameter 'StackLabel',
            :Description => 'The label of the stack to be created (e.g. report servers, web servers).  Also used as a mongodb replicaset name',
            :Type => 'String',
            :MinLength => '1',
            :MaxLength => '255',
            :AllowedPattern => '[\\x20-\\x7E]*',
            :ConstraintDescription => 'can only contain ASCII characters'

  mapping 'RegionMap',
          :'us-east-1' => { :TemplateLocation => 'https://s3.amazonaws.com/gswallow-cfn-templates-us-east-1' },
          :'us-west-2' => { :TemplateLocation => 'https://s3.amazonaws.com/gswallow-cfn-templates-us-west-2' }

  mapping 'RegionZoneMap',
          :'us-east-1' => { :AZ1 => 'us-east-1a', :AZ2 => 'us-east-1b', :AZ3 => 'us-east-1c', :AZ4 => 'us-east-1d', :AZ5 => 'us-east-1e' },
          :'us-west-2' => { :AZ1 => 'us-west-2a', :AZ2 => 'us-west-2b', :AZ3 => 'us-west-2c', :AZ4 => 'us-west-2b', :AZ5 => 'us-west-2c' }

  resource 'CfnUser', :Type => 'AWS::IAM::User', :Properties => {
      :Path => '/',
      :Policies => [
          {
              :PolicyName => 'root',
              :PolicyDocument => {
                  :Statement => [
                      {
                          :Effect => 'Allow',
                          :Action => [
                              'cloudformation:DescribeStackResource',
                              'cloudformation:DescribeStacks',
                              'cloudformation:DescribeStackEvents',
                              'cloudformation:GetTemplate',
                              'cloudformation:ValidateTemplate',
                              's3:Get',
                          ],
                          :Resource => '*',
                      },
                  ],
              },
          },
      ],
  }

  resource 'HostKeys', :Type => 'AWS::IAM::AccessKey', :Properties => { :UserName => ref('CfnUser') }

  resource 'BucketPolicy', :Type => 'AWS::S3::BucketPolicy', :Properties => {
      :PolicyDocument => {
          :Version => '2008-10-17',
          :Id => 'ReadPolicy',
          :Statement => [
              {
                  :Sid => 'ReadAccess',
                  :Action => [ 's3:GetObject' ],
                  :Effect => 'Allow',
                  :Resource => join('', 'arn:aws:s3:::', ref('ChefServerPrivateKeyBucket'), '/*'),
                  :Principal => { :AWS => get_att('CfnUser', 'Arn') },
              },
          ],
      },
      :Bucket => ref('ChefServerPrivateKeyBucket'),
  }

  resource 'EC2SecurityGroup', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
      :GroupDescription => 'Open up SSH access',
      :SecurityGroupIngress => [
          {
              :IpProtocol => 'tcp',
              :FromPort => '22',
              :ToPort => '22',
              :CidrIp => ref('SSHLocation'),
          },
      ],
  }

  resource 'MongoSecurityGroupIngress', :Type => 'AWS::EC2::SecurityGroupIngress', :Properties => {
      :GroupName => ref('EC2SecurityGroup'),
      :IpProtocol => 'tcp',
      :FromPort => '27017',
      :ToPort => '27017',
      :SourceSecurityGroupName => ref('EC2SecurityGroup'),
  }

  resource 'StatusIngress', :Type => 'AWS::EC2::SecurityGroupIngress', :Properties => {
      :GroupName => ref('EC2SecurityGroup'),
      :IpProtocol => 'tcp',
      :FromPort => '28017',
      :ToPort => '28017',
      :SourceSecurityGroupName => ref('EC2SecurityGroup'),
  }

  set = Array.new
  1.upto 3 do |m|

    az = getUniqueAZ(set)
    set << az

  resource "ReplicaSetMember#{m}",
    :Type => 'AWS::CloudFormation::Stack',
    :DependsOn => 'BucketPolicy',
    :Metadata => {
      :Comment => 'Single-instance autoscaling group containing a MongoDB replicaset member',
      :'AWS::CloudFormation::Init' => {
        :config => {
          :files => {
            :'/etc/chef/node.json' => {
              :content => {
                :run_list => []
              },
              :mode => '000644',
              :owner => 'root',
              :group => 'wheel'
            },
            :'/etc/chef/chef.json' => {
              :content => {
                :chef_client => {
                  :server_url => ref('ChefServerURL'),
                  :validation_client_name => ref('ChefValidationClientUsername')
                },
                :run_list => [ 'recipe[chef-client::config]' ]
              },
              :mode => '000644',
              :owner => 'root',
              :group => 'wheel'
            },
            :'/etc/chef/roles.json' => {
              :content => {
                :mongodb => { :replicaset_name => ref('StackLabel') },
                :run_list => [ 'role[base]', 'role[mongo_server]' ]
              },
              :mode => '000644',
              :owner => 'root',
              :group => 'wheel'
            },
            :'/home/ubuntu/.s3cfg' => {
              :content => join('', "[default]\n", 'access_key = ', ref('HostKeys'), "\n", 'secret_key = ', get_att('HostKeys', 'SecretAccessKey'), "\n", "use_https = True\n"),
              :mode => '000600',
              :owner => 'root',
              :group => 'wheel'
            }
          }
        }
      }
    },
    :Properties => {
      :TemplateURL => join('/', join('-', 'https://s3.amazonaws.com/gswallow-cfn-templates', aws_region), 'chef-node.template'),
      :Parameters => {
          :RecipeURL => 'https://s3.amazonaws.com/gswallow-cfn-templates-us-east-1/bootstrap-latest.tar.gz',
          :KeyName => ref('KeyName'),
          :InstanceType => ref('InstanceType'),
          :VolumeSize => ref('VolumeSize'),
          :StackNameOrId => ref('AWS::StackId'),
          :EC2SecurityGroup => ref('EC2SecurityGroup'),
          :InstanceZone => find_in_map('RegionZoneMap', aws_region, "AZ#{az}"),
          :ChefServerURL => ref('ChefServerURL'),
          :ChefServerPrivateKeyBucket => ref('ChefServerPrivateKeyBucket'),
          :ChefEnvironment => ref('ChefEnvironment'),
          :ResourceName => 'ReplicaSetMember1',
      }
    }
  end


end.exec!
