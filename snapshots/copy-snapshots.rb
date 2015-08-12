#!/usr/bin/env ruby

require_relative 'find-snapshots'
require 'trollop'
require 'fog'

opts = Trollop::options do
  opt :from, 'AWS region to copy from', :type => :string, :default => 'us-east-1'
  opt :to, 'AWS Region to copy to', :type => :string, :default => 'us-west-2'
  opt :id, 'Backup ID of snapshots to copy', :type => :string
end

class EC2SnapshotCopier
  def initialize(from, to, id = nil)
    @from = from
    @to = to
    @source = setup_connection(@from)
    @target = setup_connection(@to)
    @finder = EC2SnapshotFinder.new(@from)
    @id = self.get_last if id.nil?
  end

  def setup_connection(region)
    Fog::Compute.new(:provider => 'AWS', :region => region, :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'], :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def get_last
    @finder.get_last_backup
  end

  def copy(id)
    puts "Copying backups with id=#{id} from #{@from} to #{@to}"
    @finder.find_snapshots(id).each do |snap|
      puts "Copying snapshot #{snap}"
      res = @target.copy_encrypted_snapshot(snap, @from, @to, get_key, "Copy of #{snap} from #{@from} backup_id #{id}")
      new_snap = extract(res)['snapshotId']
      wait_for(new_snap)
    end
  end

  def wait_for(snap)
    loop do
      attrs = get_attrs(snap)
      puts "DEBUG: #{attrs}"
      puts "#{Time.now} Progress of #{snap} copy is #{attrs['progress']}, status is #{attrs['status']}."
      break unless attrs['status'] == 'pending'
      sleep 10
    end
  end

  def get_attrs(snap)
    extract(@target.describe_snapshots('snapshot-id' => snap))['snapshotSet'].first
  end

  def id
    @id
  end

  def get_key
    kms = Fog::AWS::KMS.new(:region => @to)
    kms.keys.map { |k| k.id }.map { |id| kms.describe_key(id).body['KeyMetadata']['Arn'] if kms.describe_key(id).body['KeyMetadata']['Description'] == 'Default master key that protects my EBS volumes when no other key is defined' }.compact.first
  end

  private

  def extract(response)
    response.body #if response.status == 200
  end
end

copy = EC2SnapshotCopier.new(opts[:from], opts[:to], opts[:id])
copy.copy(copy.id)
