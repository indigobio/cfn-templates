SparkleFormation.dynamic(:scheduled_action_down) do |_name, _config = {}|

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

  parameters("#{_name}_down_recurrence".to_sym) do
    type 'String'
    allowed_pattern "([-\\d\\/,*]+\\s+){4}[-\\d\\/,*]+"
    default '0 0 * * *'
    description "Use crontab format (see https://en.wikipedia.org/wiki/Cron).  UTC."
  end

  resources("#{_name}_scheduled_action_down".to_sym) do
    type 'AWS::AutoScaling::ScheduledAction'
    properties do
      auto_scaling_group_name ref!(_config[:autoscaling_group])
      min_size 0
      desired_capacity 0
      max_size 0
      recurrence ref!("#{_name}_down_recurrence".to_sym)
    end
  end
end