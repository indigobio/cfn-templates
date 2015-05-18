#!/usr/bin/env ruby

require 'yaml'
require 'trollop'
require 'fog'

CONFIG = YAML.load_file(File.expand_path('../config.yml', __FILE__))

opts = Trollop::options do
  opt :region, "AWS region", :type => :string, :default => CONFIG['aws']['region']
end

class EC2SnapshotFinder
  def initialize(region)
    @connection = Fog::Compute.new({ :provider => 'AWS', :region => region })
  end

  def find_backups
    snapshots = extract(@connection.describe_snapshots)['snapshotSet'].collect { |ss| ss if ss['status'] == "completed" }.compact
    snapshots.collect { |ss| "#{ss['tagSet']['backup_id']} #{ss['tagSet']['kind']}" if ss['tagSet']['backup_id'] }.compact.uniq.sort
  end

  def get_last_backup
    find_backups.last.split(' ').first
  end

  def find_snapshots(backup_id)
    snapshots = extract(@connection.describe_snapshots)['snapshotSet'].select { |ss| ss['tagSet'].include?('backup_id')}
    snapshots.collect { |ss| ss['snapshotId'] if ss['tagSet']['backup_id'].downcase.include?(backup_id.downcase) }.compact
  end

  def find_snapshot_size(snapshot)
    extract(@connection.describe_snapshots('snapshot-id' => snapshot))['snapshotSet'].first['volumeSize']
  end
  private

  def extract(response)
    response.body if response.status == 200
  end
end

puts "The following backups are available in #{opts[:region]}:"
EC2SnapshotFinder.new(opts[:region]).find_backups.each do |b|
  puts b
end
