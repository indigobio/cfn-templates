SparkleFormation.dynamic(:scheduled_action) do |_name, _config = {}|

  # {
  #   "Type" : "AWS::AutoScaling::ScheduledAction",
  #   "Properties" : {
  #     "AutoScalingGroupName" : String,
  #     "DesiredCapacity" : Integer,
  #     "EndTime" : Time stamp,
  #     "MaxSize" : Integer,
  #     "MinSize" : Integer,
  #     "Recurrence" : String,
  #     "StartTime" : Time stamp
  #   }
  # }

  parameters("#{_name}_scheduled_action_min_size".to_sym) do
    type 'Number'
    min_value _config.fetch(:min_size, 0)
    default _config.fetch(:min_size, 0)
    description "The minimum number of instances to maintain in the #{_name} auto scaling group"
  end

  parameters("#{_name}_scheduled_action_desired_capacity".to_sym) do
    type 'Number'
    min_value _config.fetch(:desired_capacity, 0)
    default _config.fetch(:desired_capacity, 0)
    description "The desired number of instances to maintain in the #{_name} auto scaling group"
  end

  parameters("#{_name}_scheduled_action_max_size".to_sym) do
    type 'Number'
    min_value _config.fetch(:max_size, 1)
    default _config.fetch(:max_size, 1)
    description "The maximum number of instances to maintain in the #{_name} auto scaling group"
  end

  parameters("#{_name}_recurrence".to_sym) do
    type 'String'
    allowed_pattern "([-\\d\\/,*]+\\s+){4}[-\\d\\/,*]+"
    default _config.fetch(:recurrence, '0 0 * * *')
    description "Use crontab format (see https://en.wikipedia.org/wiki/Cron).  UTC."
  end

  resources("#{_name}_scheduled_action".to_sym) do
    type 'AWS::AutoScaling::ScheduledAction'
    properties do
      auto_scaling_group_name _config[:autoscaling_group]
      min_size ref!("#{_name}_scheduled_action_min_size".to_sym)
      desired_capacity ref!("#{_name}_scheduled_action_desired_capacity".to_sym)
      max_size ref!("#{_name}_scheduled_action_max_size".to_sym)
      recurrence ref!("#{_name}_recurrence".to_sym)
    end
  end
end