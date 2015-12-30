SparkleFormation.dynamic(:iam_ecs_role) do |_name, _config = {}|

  _config[:policy_statements] ||= []

  resources("#{_name}_iam_ecs_role".to_sym) do
    type 'AWS::IAM::Role'
    properties do
      assume_role_policy_document do
        version '2012-10-17'
        statement _array(
          -> {
            effect 'Allow'
            principal do
              service _array( "ecs.amazonaws.com" )
            end
            action _array( "sts:AssumeRole" )
          }
        )
      end
      path '/'
    end
  end

  resources("#{_name}_iam_ecs_policy".to_sym) do
    type 'AWS::IAM::Policy'
    depends_on "#{_name.capitalize}IamEcsRole"
    properties do
      policy_name 'EcsAccess'
      policy_document do
        version '2012-10-17'
        statement _array(
          *_config[:policy_statements].map { |s| registry!(s.to_sym) }
        )
      end
      roles _array( ref!("#{_name}_iam_ecs_role".to_sym) )
    end
  end
end
