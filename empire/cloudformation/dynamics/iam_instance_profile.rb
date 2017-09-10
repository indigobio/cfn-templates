SparkleFormation.dynamic(:iam_instance_profile) do |_name, _config = {}|

  resources("#{_name}_iam_instance_profile".to_sym) do
    depends_on "#{_name.capitalize}IamPolicy"
    type 'AWS::IAM::InstanceProfile'
    properties do
      path '/'
      roles _config.fetch(:roles, []).map { |r| ref!(r) }
    end
  end
end
