require 'sparkle_formation'
require_relative('../../../utils/environment')
require_relative('../../../utils/lookup')

lookup = Indigo::CFN::Lookups.new
bucket = lookup.find_bucket(ENV['environment'], 'lambda')

SparkleFormation.new('deregister_chef_node').load(:git_rev_outputs).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an AWS Lambda that deregisters ECS cluster instances upon instance termination in an auto-scaling group.
EOF

  dynamic!(:iam_policy, 'DeregisterEcsInstance', :policy_statements => [ :list_ecs_clusters_and_members, :deregister_ecs_cluster_member ])

  dynamic!(:iam_role, 'DeregisterEcsInstance')

  # Totally a hack.  https://github.com/serverless/serverless/pull/1934
  dynamic!(:dummy_log_group, 'DeregisterEcsInstance')

  dynamic!(:sns_topic,
           "#{ENV['org']}-#{ENV['environment']}-deregister-ecs-instance",
           :subscriber => 'DeregisterEcsInstanceLambdaFunction')

  dynamic!(:lambda_permission,
           'DeregisterEcsInstance',
           :sns_topic => "#{ENV['org']}-#{ENV['environment']}-deregister-ecs-instance-sns-topic".gsub('-', '_').to_sym,
           :lambda => 'DeregisterEcsInstanceLambdaFunction')

  dynamic!(:lambda_function,
           'DeregisterEcsInstance',
           :timeout => 30,
           :bucket => bucket,
           :key => 'deregister_ecs_instance/deregister_ecs_instance.zip',
           :handler => 'deregister_ecs_instance.lambda_handler',
           :role => 'DeregisterEcsInstanceIamRole')
end
