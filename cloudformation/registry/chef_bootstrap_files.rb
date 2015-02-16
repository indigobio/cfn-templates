SparkleFormation::Registry.register(:chef_bootstrap_files) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files('/etc/chef/client.rb') do
        content join!(
                  "chef_server_url             \"", ref!('ChefServerURL'), "\"\n",
                  "validation_client_name      \"", ref!(:chef_validation_client_name), "\"\n",
                  "log_level                   :info\n",
                  "log_location                STDOUT\n",
                  "file_cache_path             \"/var/chef-solo\"\n",
                  "cookbook_path               \"/var/chef-solo/cookbooks\"\n",
                  "enable_reporting_url_fatals false\n"
                )
        mode '000644'
        owner 'root'
        group 'root'
      end
      files('/etc/chef/first-run.json') do
        content join!(
                  "{\n",
                  "  \"run_list\": [ \"",
                  join!( ref!(:chef_run_list), {:options => { :delimiter => '", "'}}),
                  "\" ]\n",
                  "}\n"
                )
        mode '000644'
        owner 'root'
        group 'root'
      end
      files('/home/ubuntu/.s3cfg') do
        content join!(
                  "[default]\n",
                  "access_key = ", ref!(:cfn_keys), "\n",
                  "secret_key = ", attr!(:cfn_keys, :secret_access_key), "\n",
                  "use_https = True\n"
                )
        mode '000644'
        owner 'root'
        group 'root'
      end
    end
  end
end
