require 'sparkle_formation'
require_relative('../../../utils/environment')
require_relative('../../../utils/lookup')

lookup = Indigo::CFN::Lookups.new
bucket = lookup.find_bucket(ENV['environment'], 'lambda')

SparkleFormation.new('deregister_chef_node').load(:git_rev_outputs).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description <<EOF
Creates an AWS Lambda that deregisters Chef nodes upon instance termination in an auto-scaling group.
EOF

  dynamic!(:iam_policy, 'DeregisterChefNode')

  dynamic!(:iam_role, 'DeregisterChefNode')

  # Totally a hack.  https://github.com/serverless/serverless/pull/1934
  dynamic!(:dummy_log_group, 'DeregisterChefNode')

  dynamic!(:sns_topic,
           "#{ENV['org']}-#{ENV['environment']}-deregister-chef-node",
           :subscriber => 'DeregisterChefNodeLambdaFunction')

  dynamic!(:lambda_permission,
           'DeregisterChefNode',
           :sns_topic => "#{ENV['org']}-#{ENV['environment']}-deregister-chef-node-sns-topic".gsub('-', '_').to_sym,
           :lambda => 'DeregisterChefNodeLambdaFunction')

  dynamic!(:lambda_function,
           'DeregisterChefNode',
           :timeout => 30,
           :bucket => bucket,
           :key => 'deregister_chef_node/deregister_chef_node.zip',
           :handler => 'deregister_chef_node.lambda_handler',
           :role => 'DeregisterChefNodeIamRole')
end
