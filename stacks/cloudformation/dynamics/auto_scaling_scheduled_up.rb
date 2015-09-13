SparkleFormation.dynamic(:scheduled_action_up) do |_name, _config = {}|

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

  parameters("#{_name}_up_recurrence".to_sym) do
    type 'String'
    allowed_pattern "([-\\d\\/,*]+\\s+){4}[-\\d\\/,*]+"
    default '0 0 * * *'
    description "Use crontab format (see https://en.wikipedia.org/wiki/Cron).  UTC."
  end

  resources("#{_name}_scheduled_action_up".to_sym) do
    type 'AWS::AutoScaling::ScheduledAction'
    properties do
      auto_scaling_group_name ref!(_config[:autoscaling_group])
      min_size ref!("#{_name}_min_size".to_sym)
      desired_capacity ref!("#{_name}_desired_capacity".to_sym)
      max_size ref!("#{_name}_max_size".to_sym)
      recurrence ref!("#{_name}_up_recurrence".to_sym)
    end
  end
end