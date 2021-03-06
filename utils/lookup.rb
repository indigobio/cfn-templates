require 'fog'

class Indigo
  class CFN
    class Lookups
      def initialize
        Fog.credentials = {
            :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
            :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
            :region => ENV['AWS_DEFAULT_REGION']
        }
        @compute = Fog::Compute.new({ :provider => 'AWS' })
        @s3 = Fog::Storage.new({ :provider => 'AWS', :region => ENV['AWS_DEFAULT_REGION'] })
      end

      # Done.
      def get_azs
        extract(@compute.describe_availability_zones)['availabilityZoneInfo'].collect { |z| z['zoneName'] }
      end

      # Done.
      def get_vpc
        vpcs = extract(@compute.describe_vpcs)['vpcSet']
        vpcs.find { |vpc| vpc['tagSet'].fetch('Environment', nil) == ENV['environment']}['vpcId']
      end

      # Done.
      def get_subnets(vpc)
        subnets = extract(@compute.describe_subnets)['subnetSet']
        subnets.collect! { |sn| sn['subnetId'] if sn['tagSet'].fetch('Network', nil) == ENV['net_type'] and sn['vpcId'] == vpc }.compact!
      end

      # Done.
      def get_public_subnets(vpc)
        subnets = extract(@compute.describe_subnets)['subnetSet']
        subnets.collect! { |sn| { :name => sn['tagSet']['Name'].gsub(/[^-.a-zA-Z0-9]/, '-'), :id => sn['subnetId'] } if sn['tagSet'].fetch('Network', nil) == 'Public' and sn['vpcId'] == vpc}.compact!
      end

      # Done.
      def get_public_subnet_ids(vpc)
        get_public_subnets(vpc).collect { |sn| sn[:id] }
      end

      # Done.
      def get_public_subnet_names(vpc)
        get_public_subnets(vpc).collect { |sn| sn[:name] }
      end

      # Done.
      def get_private_subnets(vpc)
        subnets = extract(@compute.describe_subnets)['subnetSet']
        subnets.collect! { |sn| { :name => sn['tagSet']['Name'].gsub(/[^-.a-zA-Z0-9]/, '-'), :id => sn['subnetId'] } if sn['tagSet'].fetch('Network', nil) == 'Private' and sn['vpcId'] == vpc}.compact!
      end

      # Done.
      def get_private_subnet_ids(vpc)
        get_private_subnets(vpc).collect { |sn| sn[:id] }
      end

      # Done.
      def get_private_subnet_names(vpc)
        get_private_subnets(vpc).collect { |sn| sn[:name] }
      end

      # Done.
      def get_security_groups(vpc, group = nil)
        sgs = Array.new
        group = ENV['sg'] if group.nil?
        group.split(',').each do |sg|
          found_sgs = extract(@compute.describe_security_groups)['securityGroupInfo']
          if sg == '*'
            found_sgs.collect! { |fsg| { :name => fsg['groupName'].gsub(/[^-.a-zA-Z0-9]/, '-'), :id => fsg['groupId'] } if fsg['vpcId'] == vpc }.compact!
          else
            found_sgs.collect! { |fsg| { :name => fsg['groupName'].gsub(/[^-.a-zA-Z0-9]/, '-'), :id => fsg['groupId'] } if fsg['tagSet'].fetch('Name', nil) == sg and fsg['vpcId'] == vpc }.compact!
          end
          sgs.concat found_sgs
        end
        sgs
      end

      # Done.
      def get_security_group_names(vpc, group = nil)
        get_security_groups(vpc, group).collect { |sg| sg[:name] }
      end

      # Done.
      def get_security_group_ids(vpc, group = nil)
        get_security_groups(vpc, group).collect { |sg| sg[:id] }
      end

      # Done!
      def get_snapshots
        snapshots = Array.new(ENV['snapshots'].split(','))
        unless ENV['backup_id'].empty?
          found_snaps = extract(@compute.describe_snapshots)['snapshotSet'].select { |ss| ss['tagSet'].include?('backup_id')}
          what_i_want = found_snaps.collect { |ss| ss['snapshotId'] if ss['tagSet']['backup_id'].downcase.include?(ENV['backup_id'].downcase) }.compact
          snapshots.concat what_i_want
        end
        snapshots
      end

      # Done.
      def get_ssl_certs
        @iam = Fog::AWS::IAM.new(:region => nil)
        extract(@iam.list_server_certificates)['Certificates'].collect { |c| c['Arn'] }.compact
      end

      # Done.
      def get_notification_topic
        @sns = Fog::AWS::SNS.new
        topics = extract(@sns.list_topics)['Topics']
        topics.find { |e| e =~ /#{ENV['notification_topic']}/ }
      end

      # Done.
      def get_rds_snapshots(identifier)
        @rds = Fog::AWS::RDS.new
        all_snaps = extract(@rds.describe_db_snapshots)['DescribeDBSnapshotsResult']['DBSnapshots']
        my_snaps = all_snaps.collect { |s| s if s['DBInstanceIdentifier'] == identifier }
        my_snaps.sort { |a, b| b['SnapshotCreateTime'] <=> a['SnapshotCreateTime'] }
      end

      # Done.
      def get_latest_rds_snapshot(identifier)
        get_rds_snapshots(identifier).first['DBSnapshotIdentifier'] or false
      end

      # Done.
      def get_zone_id(zone)
        @dns = Fog::DNS.new(:provider => 'AWS')
        @dns.zones.map { |z| z.id if z.domain =~ /#{zone}\.?/ }.compact.first
      end

      # Done.  Phew.
      def find_bucket(env, purpose)
        @s3.directories.collect { |d| d.key if d.location == ENV['AWS_DEFAULT_REGION'] }.compact.each do |bucket|
          begin
            tags = extract(@s3.get_bucket_tagging(bucket))['BucketTagging']
            return bucket if tags.fetch('Environment', nil) == env and tags.fetch('Purpose', nil) == purpose
          rescue Excon::Errors::NotFound, Excon::Errors::SocketError
          end
        end
        nil
      end

      # Done.
      def get_elb(purpose)
        @elb = Fog::AWS::ELB.new(:region => ENV['AWS_DEFAULT_REGION'])
        my_elbs.each do |b|
          tags = extract(@elb.describe_tags(b['LoadBalancerName']))['DescribeTagsResult']['LoadBalancers'].first['Tags']
          return b['LoadBalancerName'] if tags.fetch('Purpose', nil) == purpose
        end
        nil
      end

      # Done.
      def my_elbs
        all_elbs.map { |b| b if b['VPCId'] == get_vpc}.compact
      end

      # Done.
      def all_elbs
        extract(@elb.describe_load_balancers)['DescribeLoadBalancersResult']['LoadBalancerDescriptions']
      end

      private

      # Not needed.
      def extract(response)
        response.body if response.status == 200
      end
    end
  end
end

