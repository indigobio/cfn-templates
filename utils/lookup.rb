require 'fog'

class Indigo
  class CFN
    class Lookups
      def initialize
        Fog.credentials = {
            :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
            :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
            :region => ENV['region']
        }
        @compute = Fog::Compute.new({ :provider => 'AWS' })
      end

      def get_azs
        extract(@compute.describe_availability_zones)['availabilityZoneInfo'].collect { |z| z['zoneName'] }
      end

      def get_ssl_certs
        @iam = Fog::AWS::IAM.new(:region => nil)
        extract(@iam.list_server_certificates)['Certificates'].collect { |c| c['Arn'] }.compact
      end

      def get_vpc
        vpcs = extract(@compute.describe_vpcs)['vpcSet']
        vpcs.find { |vpc| vpc['tagSet'].fetch('Environment', nil) == ENV['environment']}['vpcId']
      end

      def get_subnets(vpc)
        subnets = extract(@compute.describe_subnets)['subnetSet']
        subnets.collect! { |sn| sn['subnetId'] if sn['tagSet'].fetch('Network', nil) == ENV['net_type'] and sn['vpcId'] == vpc }.compact!
      end

      def get_security_groups(vpc)
        sgs = Array.new
        ENV['sg'].split(',').each do |sg|
          found_sgs = extract(@compute.describe_security_groups)['securityGroupInfo']
          found_sgs.collect! { |fsg| fsg['groupId'] if fsg['tagSet'].fetch('Name', nil) == sg and fsg['vpcId'] == vpc }.compact!
          sgs.concat found_sgs
        end
      end

      def get_notification_topic
        @sns = Fog::AWS::SNS.new
        topics = extract(@sns.list_topics)['Topics']
        topics.find { |e| e =~ /#{ENV['notification_topic']}/ }
      end

      private

      def extract(response)
        response.body if response.status == 200
      end
    end
  end
end
