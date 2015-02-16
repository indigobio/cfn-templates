SparkleFormation.new('vpc').load(:deregistration).overrides do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description "Node Deregistration Queue"
end