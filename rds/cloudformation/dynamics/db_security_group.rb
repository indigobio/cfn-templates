SparkleFormation.dynamic(:db_security_group) do |_name, _config = {}|

  # {
  #   "CIDRIP": String,
  #   "DBSecurityGroupName": String,
  #   "EC2SecurityGroupId": String,
  #   "EC2SecurityGroupName": String,
  #   "EC2SecurityGroupOwnerId": String
  # }

  # {
  #   "Type" : "AWS::RDS::DBSecurityGroup",
  #   "Properties" : {
  #     "EC2VpcId" : { "Ref" : "myVPC" },
  #     "DBSecurityGroupIngress" : [ RDS Security Group Rule object 1, ... ],
  #     "GroupDescription" : String,
  #     "Tags" : [ Resource Tag, ... ]
  #   }
  # }

  resources("#{_name}_db_security_group".gsub('-','_').to_sym) do
    type 'AWS::RDS::DBSecurityGroup'
    properties do
      e_c2_vpc_id _config[:vpc]
      d_b_security_group_ingress _array(
        *_config[:security_group].map { |sg|
          -> {
            e_c2_security_group_id sg
          }
        }
      )
      group_description "#{_name}_db_security_group".gsub('-','_').to_sym
    end
  end
end

