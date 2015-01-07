#!/usr/bin/env ruby

require 'trollop'
require 'fog'

opts = Trollop::options do
  opt :region, 'AWS region to search', :default => 'us-east-1'
end

class EC2SnapshotShow
  def initialize(region)
    @connection = Fog::Compute.new({ :provider => 'AWS', :region => region })
  end

  def find_snapshots
    extract(@connection.describe_snapshots)['snapshotSet'].collect { |ss| ss if ss['status'] == "completed" }.compact
  end

  private

  def extract(response)
    response.body if response.status == 200
  end

end

puts "Available backups in #{opts[:region]}:"
snapshots = EC2SnapshotShow.new(opts[:region]).find_snapshots
snapshots.collect { |ss| "#{ss['tagSet']['backup_id']} #{ss['tagSet']['kind']}" if ss['tagSet']['backup_id'] }.compact.uniq.sort.each do |ss|
  puts ss
end
