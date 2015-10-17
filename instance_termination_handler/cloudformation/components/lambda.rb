SparkleFormation.build do

# {
#   "Type" : "AWS::Lambda::Function",
#   "Properties" : {
#     "Code" : Code,
#     "Description" : String,
#     "Handler" : String,
#     "MemorySize" : Integer,
#     "Role" : String,
#     "Runtime" : String,
#     "Timeout" : Integer
#   }
# }

resources(:instance_termination_handler) do
  type 'AWS::Lambda::Function'
  properties do
    code do
      s3_bucket ref!(:lambda_bucket)
      s3_key 'instance_termination/instance_termination.zip'
    end
    description 'Instance Termination Notifications Handler'
    handler 'instance_termination.lambda_handler'
    memory_size '128'
    runtime 'python2.7'
    timeout '5'
  end
end