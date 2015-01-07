#!/usr/bin/env ruby

require 'yaml'
require 'trollop'
require 'fog'

CONFIG = YAML.load_file(File.expand_path('../config.yml', __FILE__))

opts = Trollop::options do
  opt :name, 'Name for the created instance', :default => 'test-restore'
  opt :tag, 'Snapshot tag', :type => :string
  opt :template, 'CFN template', :type => :string
end

class EC2VPCFinder
  def initialize(region)
    @connection = Fog::Compute.new({ :provider => 'AWS', :region => region })
  end

  def find_vpc(vpc_name)
    vpcset = extract(@connection.describe_vpcs)['vpcSet']
    unless vpcset.nil?
      vpcset.select { |vpc| vpc['tagSet'].has_key?('Name') and vpc['tagSet']['Name'].downcase.include?(vpc_name) }.first['vpcId']
    end
  end

  private

  def extract(response)
    response.body if response.status == 200
  end
end

class EC2SubnetFinder
  def initialize(region)
    @connection = Fog::Compute.new({ :provider => 'AWS', :region => region })
  end

  def find_subnets_of(vpc, match)
    subnets = extract(@connection.describe_subnets)['subnetSet'].select { |sn| sn['vpcId'] == vpc }
    subnets.collect { |sn| sn['subnetId'] if sn['tagSet'].has_key?('Name') and sn['tagSet']['Name'].downcase.include?(match.downcase) }.compact
  end
  
  private

  def extract(response)
    response.body if response.status == 200
  end
end

class EC2SecurityGroupFinder
  def initialize(region)
    @connection = Fog::Compute.new({ :provider => 'AWS', :region => region })
  end

  def find_security_group(vpc_id, match)
    security_groups = extract(@connection.describe_security_groups)['securityGroupInfo'].select { |sg| sg['vpcId'] == vpc_id }
    security_groups.collect { |sg| sg['groupId'] if sg['groupName'].downcase.include?(match.downcase) }.compact
  end

  private

  def extract(response)
    response.body if response.status == 200
  end
end

class EC2SnapshotFinder
  def initialize(region)
    @connection = Fog::Compute.new({ :provider => 'AWS', :region => region })
  end

  def find_snapshots(tag)
    snapshots = extract(@connection.describe_snapshots)['snapshotSet'].select { |ss| ss['tagSet'].include?('backup_id')}
    snapshots.collect { |ss| ss['snapshotId'] if ss['tagSet']['backup_id'].downcase.include?(tag.downcase) }.compact
  end

  def find_snapshot_size(snapshot)
    extract(@connection.describe_snapshots('snapshot-id' => snapshot))['snapshotSet'].first['volumeSize']
  end
  private

  def extract(response)
    response.body if response.status == 200
  end
end

class CFNCreateStack
  def initialize(region)
    @cfn = Fog::AWS::CloudFormation.new({:region => region })
  end

  def create_stack(name, template, subnets, security_groups, snapshots)
    params = {
      'ChefEnvironment'              => CONFIG['chef']['environment'],
      'ChefRunListItems'             => CONFIG['chef']['runlist_items'],
      'ChefServerPrivateKeyBucket'   => CONFIG['chef']['server_private_key_bucket'],
      'ChefServerURL'                => CONFIG['chef']['server_url'],
      'ChefValidationClientUsername' => CONFIG['chef']['validation_client_username'],
      'DesiredCapacity'              => CONFIG['aws']['desired_capacity'],
      'EBSOptimized'                 => CONFIG['aws']['ebs_optimized'],
      'InstanceNameTag'              => CONFIG['aws']['instance_name_tag'],
      'InstanceType'                 => CONFIG['aws']['instance_type'],
      'KeyName'                      => CONFIG['aws']['ssh_key_name'],
      'SSHLocation'                  => CONFIG['aws']['ssh_location'],
      'VolumeSize'                   => CONFIG['aws']['ebs_volume_size'], # 0 to disable
      'VolumeType'                   => CONFIG['aws']['ebs_volume_type'],
      'VolumePiopsRatio'             => CONFIG['aws']['ebs_volume_piops_ratio'],
      'SubnetIds'                    => subnets.join(','),
      'VPCSecurityGroups'            => security_groups.join(',')
    }

    unless snapshots.empty?
      params['UseSnapshots'] = 'true'
      params['SnapshotRaidSize'] = raidsize(snapshots)
      params['SnapshotRaidCount'] = snapshots.count
      params['Snapshots'] = snapshots.join(',')
    end

    @cfn.create_stack(
      name,
      options = {
        'TemplateBody' => File.open(template, 'rb').read,
        'Parameters' => params,
        'DisableRollback' => CONFIG['cfn']['disable_rollback'],
        'TimeoutInMinutes' => CONFIG['cfn']['timeout_in_minutes'],
        'Capabilities' => [ 'CAPABILITY_IAM' ]
      })
  end

  def raidsize(snapshots)
    EC2SnapshotFinder.new(CONFIG['aws']['region']).find_snapshot_size(snapshots.first).to_i * snapshots.count
  end
end

vpc = EC2VPCFinder.new(CONFIG['aws']['region']).find_vpc(CONFIG['aws']['vpc_name'])
subnets = EC2SubnetFinder.new(CONFIG['aws']['region']).find_subnets_of(vpc, CONFIG['aws']['subnet_name'])
security_groups = EC2SecurityGroupFinder.new(CONFIG['aws']['region']).find_security_group(vpc, CONFIG['aws']['security_group_name'])
snapshots = EC2SnapshotFinder.new(CONFIG['aws']['region']).find_snapshots(opts[:tag])

puts "Will create a new node in VPC #{vpc}, in one of subnets #{subnets.join(',')}, with security group(s) #{security_groups.join(',')} and snapshots #{snapshots.join(',')}"

CFNCreateStack.new(CONFIG['aws']['region']).create_stack(opts[:name], opts[:template], subnets, security_groups, snapshots)
