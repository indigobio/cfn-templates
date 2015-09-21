SfnRegistry.register(:chef_bootstrap_files) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files('/etc/chef/client.rb') do
        content join!(
                  "chef_server_url             \"", ref!(:chef_server_url), "\"\n",
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
      files('/home/ubuntu/.s3cfg') do
        content join!(
                  "[default]\n",
                  "access_key =\n",
                  "secret_key =\n",
                  "security_token =\n",
                  "use_https = True\n"
                )
        mode '000644'
        owner 'root'
        group 'root'
      end
    end
  end
end
