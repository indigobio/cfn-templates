SparkleFormation.build do

  mappings(:engine_to_latest_version) do
    set!('MySQL'._no_hump, :version => '5.6.23')
    set!('oracle-ee'._no_hump, :version => '12.2.0.1.v1')
    set!('postgres'._no_hump, :version => '9.4.1')
    set!('sqlserver-se'._no_hump, :version => '11.00.2100.60.v1')
    set!('sqlserver-ex'._no_hump, :version => '11.00.2100.60.v1')
    set!('sqlserver-web'._no_hump, :version => '11.00.2100.60.v1')
  end
end
