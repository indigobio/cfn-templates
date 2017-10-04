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

  _config[:scheme]   ||= 'internet-facing'
  _config[:lb_name]  ||= ENV['lb_name']
  _config[:policies] ||= []
  _config[:idle_timeout] ||= '60'


  parameters("#{_name}_lb_name".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:lb_name]
    description 'Name of public Elastic Load Balancer'
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_lb_draining_enabled".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:draining_policy, 'true')
    description "Enable connection draining"
  end

  parameters("#{_name}_lb_draining_timeout".to_sym) do
    type 'Number'
    max_value 3600
    min_value 1
    default _config.fetch(:draining_timeout, 300)
    description "Connection drain timeout.  Use a value between 1 and 3600."
  end

  resources("#{_name.gsub('-','_')}_elb".to_sym) do
    type 'AWS::ElasticLoadBalancing::LoadBalancer'
    depends_on _array( 'VpcIgwAttachment' )
    properties do
      cross_zone 'true'
      load_balancer_name ref!("#{_name}_lb_name".to_sym)
      connection_settings do
        idle_timeout _config[:idle_timeout]
      end
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
      health_check do
        healthy_threshold "2"
        interval "10"
        target "TCP:#{_config[:listeners].first[:instance_port]}"
        timeout "5"
        unhealthy_threshold "3"
      end
      connection_draining_policy do
        enabled ref!("#{_name}_lb_draining_enabled".to_sym)
        timeout ref!("#{_name}_lb_draining_timeout".to_sym)
      end
      policies _array(
        *_config[:policies].map { |l| -> {
          policy_name l[:policy_name]
          policy_type l[:policy_type]
          attributes _array(
            *l[:attributes].each { |k, v| -> {
              k v
            }
          })
          instance_ports l[:instance_ports]
        }
      })
      scheme _config[:scheme]
      subnets _array( *_config[:subnets].map { |sn| ref!(sn.to_sym) } )
      security_groups array!(
        *_config[:security_groups].map { |sg| ref!(sg) }
      )
      tags _array(
        -> {
          key 'Purpose'
          value "#{_name.gsub('-','_')}_elb".to_sym
        },
        -> {
          key 'Environment'
          value ENV['environment']
        }
      )
    end
  end
end
