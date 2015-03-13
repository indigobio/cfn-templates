SparkleFormation.dynamic(:elb) do |_name, _config = {}|
  # {
  #   "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
  #   "Properties": {
  #     "AccessLoggingPolicy" : AccessLoggingPolicy,
  #     "AppCookieStickinessPolicy" : [ AppCookieStickinessPolicy, ... ],
  #     "AvailabilityZones" : [ String, ... ],
  #     "ConnectionDrainingPolicy" : ConnectionDrainingPolicy,
  #     "ConnectionSettings" : ConnectionSettings,
  #     "CrossZone" : Boolean,
  #     "HealthCheck" : HealthCheck,
  #     "Instances" : [ String, ... ],
  #     "LBCookieStickinessPolicy" : [ LBCookieStickinessPolicy, ... ],
  #     "LoadBalancerName" : String,
  #     "Listeners" : [ Listener, ... ],
  #     "Policies" : [ ElasticLoadBalancing Policy, ... ],
  #     "Scheme" : String,
  #     "SecurityGroups" : [ Security Group, ... ],
  #     "Subnets" : [ String, ... ],
  #     "Tags" : [ Resource Tag, ... ]
  #   }
  # }

  _config[:scheme] ||= 'internet-facing'

  resources("#{_name.gsub('-','_')}_elastic_load_balancer".to_sym) do
    type 'AWS::ElasticLoadBalancing::LoadBalancer'
    depends_on _array( 'VpcIgwAttachment' )
    properties do
      cross_zone 'true'
      listeners _array(
        *_config[:listeners].map { |l| -> {
          protocol l[:protocol] # <---------------------- TCP, SSL, HTTP or HTTPS
          load_balancer_port l[:load_balancer_port]
          instance_protocol l[:instance_protocol]
          instance_port l[:instance_port]
          if l.has_key?(:policy_names)
            policy_names _array( *l[:policy_names] )
          end
          unless l.fetch(:ssl_certificate_id, nil).nil?
            set!('SSLCertificateId', l[:ssl_certificate_id])
          end
        }})
      scheme _config[:scheme]
      subnets _array( *_config[:subnets].map { |sn| ref!(sn.to_sym) } )
      security_groups array!(
        *_config[:security_groups].map { |sg| ref!(sg) }
      )
    end
  end
end