SparkleFormation.build do

  mappings(:engine_to_latest_version) do
    camel_keys_set!(:auto_disable)
    set!('MySQL', :version => '5.6.23')
    set!('oracle-ee', :version => '12.2.0.1.v1')
    set!('postgres', :version => '9.4.1')
    set!('sqlserver-se', :version => '11.00.2100.60.v1')
    set!('sqlserver-ex', :version => '11.00.2100.60.v1')
    set!('sqlserver-web', :version => '11.00.2100.60.v1')
  end
end
