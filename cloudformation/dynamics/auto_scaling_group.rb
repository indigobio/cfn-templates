SparkleFormation.dynamic(:auto_scaling_group) do |_name, _config = {}|
  # _config[:launch_config] must be supplied, with a launch configuration name

  conditions.set!(
    "#{_name}_send_notifications".to_sym,
    not!(equals!(ref!("#{_name}_notification_topic".to_sym), 'none'))
  )

  parameters("#{_name}_min_size".to_sym) do
    type 'Number'
    min_value _config[:min_size] || 1
    max_value _config[:min_size] || 1
    default _config[:min_size] || 1
  end

  parameters("#{_name}_desired_capacity".to_sym) do
    type 'Number'
    min_value _config[:min_size] || 1
    max_value _config[:desired_capacity] || 1
    default _config[:desired_capacity] || 1
  end

  parameters("#{_name}_max_size".to_sym) do
    type 'Number'
    min_value _config[:min_size] || 1
    max_value _config[:max_size] || 1
    default _config[:max_size] || 1
  end

  parameters("#{_name}_notification_topic".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    constraint_description 'can only contain ASCII characters'
    description 'SNS notification topic to send on instance termination'
    default _config[:notification_topic] || 'none'
  end

  resources("#{_name}_asg".to_sym) do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      min_size ref!("#{_name}_min_size".to_sym)
      desired_capacity ref!("#{_name}_desired_capacity".to_sym)
      max_size ref!("#{_name}_max_size".to_sym)
      availability_zones get_azs!
      launch_configuration_name ref!(_config[:launch_config])
      notification_configuration do
        topic_a_r_n if!("#{_name}_send_notifications".to_sym, ref!("#{_name}_notification_topic".to_sym), no_value!)
        notification_types _array("autoscaling:EC2_INSTANCE_TERMINATE")
      end
    end
  end
end