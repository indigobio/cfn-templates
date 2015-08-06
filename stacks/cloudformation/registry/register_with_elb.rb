SparkleFormation::Registry.register(:register_with_elb) do
  base64! <<-EOF
curl https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o /tmp/awscli-bundle.zip
pushd /tmp
unzip awscli-bundle.zip
/tmp/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
popd
  EOF
end
