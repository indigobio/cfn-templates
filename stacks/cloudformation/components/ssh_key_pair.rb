SparkleFormation.build do
  parameters(:ssh_key_pair) do
    description 'Amazon EC2 key pair'
    type 'AWS::EC2::KeyPair::KeyName'
  end
end