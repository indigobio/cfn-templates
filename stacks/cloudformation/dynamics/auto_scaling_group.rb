SparkleFormation.dynamic(:auto_scaling_group) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::AutoScaling::AutoScalingGroup",
  #   "Properties" : {
  #     "AvailabilityZones" : [ String, ... ],
  #     "Cooldown" : String,
  #     "DesiredCapacity" : String,
  #     "HealthCheckGracePeriod" : Integer,
  #     "HealthCheckType" : String,
  #     "InstanceId" : String,
  #     "LaunchConfigurationName" : String,
  #     "LoadBalancerNames" : [ String, ... ],
  #     "MaxSize" : String,
  #     "MetricsCollection" : [ MetricsCollection, ... ]
  #     "MinSize" : String,
  #     "NotificationConfiguration" : NotificationConfiguration,
  #     "PlacementGroup" : String,
  #     "Tags" : [ Auto Scaling Tag, ..., ],
  #     "TerminationPolicies" : [ String, ..., ],
  #     "VPCZoneIdentifier" : [ String, ... ]
  #   }
  # }

  ENV['org'] ||= 'indigo'
  ENV['environment'] ||= 'dr'
  ENV['region'] ||= 'us-east-1'

  _config[:notification_topic] ||= "#{ENV['org']}-#{ENV['region']}-terminated-instances"

  parameters("#{_name}_min_size".to_sym) do
    type 'Number'
    min_value _config.fetch(:min_size, 0)
    default _config.fetch(:min_size, 0)
    description "The minimum number of instances to maintain in the #{_name} auto scaling group"
    constraint_description "Must be a number #{_config.fetch(:min_size, 1)} or higher"
  end

  parameters("#{_name}_desired_capacity".to_sym) do
    type 'Number'
    min_value _config.fetch(:desired_capacity, 1)
    default _config.fetch(:desired_capacity, 1)
    description "The desired number of instances to maintain in the #{_name} auto scaling group"
    constraint_description "Must be a number #{_config.fetch(:min_size, 1)} or higher"
  end

  parameters("#{_name}_max_size".to_sym) do
    type 'Number'
    max_value _config.fetch(:max_size, 100)
    default _config.fetch(:max_size, 1)
    description "The minimum number of instances to maintain in the #{_name} auto scaling group"
    constraint_description "Must be a number #{_config.fetch(:min_size, 100)} or lower"
  end

  parameters("#{_name}_notification_topic".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default _config[:notification_topic] || 'none'
    description 'SNS notification topic to send on instance termination'
    constraint_description 'can only contain ASCII characters'
  end

  resources("#{_name}_asg".gsub('-','_').to_sym) do
    type 'AWS::AutoScaling::AutoScalingGroup'
    if _config.has_key?(:depends_on)
      depends_on _config[:depends_on]
    end
    creation_policy do
      resource_signal do
        count ref!("#{_name}_desired_capacity".to_sym)
        timeout "PT1H"
      end
    end
    properties do
      availability_zones get_azs!
      min_size ref!("#{_name}_min_size".to_sym)
      desired_capacity ref!("#{_name}_desired_capacity".to_sym)
      max_size ref!("#{_name}_max_size".to_sym)
      v_p_c_zone_identifier _config[:subnets]
      launch_configuration_name ref!(_config[:launch_config])
      notification_configuration do
        topic_a_r_n ref!("#{_name}_notification_topic".to_sym)
        notification_types _array("autoscaling:EC2_INSTANCE_TERMINATE")
      end
      tags _array(
        -> {
          key 'Name'
          value "#{_name}_asg_instance".to_sym
          propagate_at_launch 'true'
        },
        -> {
          key 'Environment'
          value ENV['environment']
          propagate_at_launch 'true'
        }
      )
    end
  end
end
