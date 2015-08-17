require 'fog'

ENV['org'] ||= 'indigo'
ENV['environment'] ||= 'dr'
ENV['region'] ||= 'us-east-1'
pfx = "#{ENV['org']}-#{ENV['environment']}-#{ENV['region']}"

ENV['vpc_name'] ||= "#{pfx}-vpc"
ENV['cert_name'] ||= "#{pfx}-cert"
ENV['lb_name'] ||= "#{pfx}-public-elb"
ENV['public_domain'] ||= 'ascentrecovery.net'

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

      private

      def extract(response)
        response.body if response.status == 200
      end
    end
  end
end
