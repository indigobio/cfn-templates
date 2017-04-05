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

  resources("#{_name}_asg".to_sym) do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      min_size 0
      desired_capacity 1
      max_size 1
      v_p_c_zone_identifier _array(
        *_config[:subnets].map { |n| ref!(n) }
      )
      launch_configuration_name ref!(_config[:launch_config])
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
