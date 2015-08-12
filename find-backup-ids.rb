#!/usr/bin/env ruby

require 'trollop'
require_relative 'snapshots/find-snapshots'

opts = Trollop::options do
  opt :region, "AWS region", :type => :string, :default => 'us-west-2'
  opt :last, "Last backup"
end

if opts[:last]
  puts EC2SnapshotFinder.new(opts[:region]).get_last_backup
else
  puts "The following backups are available in #{opts[:region]}:"
  EC2SnapshotFinder.new(opts[:region]).find_backups.each do |b|
    puts b
  end
end
