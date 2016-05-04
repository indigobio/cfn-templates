SfnRegistry.register(:register_with_elb) do

  join!(
    "\n\ncurl https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o /tmp/awscli-bundle.zip || cfn_signal_and_exit\n",
    "pushd /tmp\n",
    "unzip awscli-bundle.zip\n",
    "/tmp/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws || cfn_signal_and_exit\n",
    "rm -rf awscli-bundle.zip awscli-bundle\n",
    "popd\n\n",

    "AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document/ | grep -i region | awk -F\\\" '{print $4}')\n",
    "INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id/)\n",
    "MAC=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)\n",
    "VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${MAC}/vpc-id/)\n",
    "AWS_CLI=\"aws --region $AWS_REGION\"\n\n",

    "elbs=$($AWS_CLI elb describe-load-balancers --query 'LoadBalancerDescriptions[].[VPCId, LoadBalancerName]' --output text | grep $VPC_ID | awk '{print $2}')\n\n",

    "for elb in $elbs; do\n",
    "  lbenv=$($AWS_CLI elb describe-tags --load-balancer-names $elb --query 'TagDescriptions[].Tags[]' --output text | grep Environment | awk '{print $2}')\n",
    "  if [ \"$lbenv\" = \"#{ENV['environment']}\" ]; then\n",
    "    purpose=$($AWS_CLI elb describe-tags --load-balancer-names $elb --query 'TagDescriptions[].Tags[]' --output text | grep Purpose | awk '{print $2}')\n",
    "    if [ \"$purpose\" = \"", ref!(:load_balancer_purpose), "\" ]; then\n",
    "      $AWS_CLI elb register-instances-with-load-balancer --load-balancer-name $elb --instances $INSTANCE_ID || cfn_signal_and_exit\n",
    "    fi\n",
    "  fi\n",
    "done\n"
  )
end
