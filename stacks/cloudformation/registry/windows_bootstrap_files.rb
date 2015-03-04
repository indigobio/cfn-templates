SparkleFormation::Registry.register(:windows_bootstrap_files) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files("c:\\chef\\client.rb") do
        content join!(
          "chef_server_url             \"", ref!(:chef_server_url), "\"\n",
          "validation_client_name      \"", ref!(:chef_validation_client_name), "\"\n",
          "log_level                   :info\n",
          "log_location                STDOUT\n",
          "file_cache_path             \"c:/chef/cache\"\n",
          "cookbook_path               \"c:/chef/cache/cookbooks\"\n",
          "enable_reporting_url_fatals false\n"
        )
      end

      files("c:\\chef\\first-boot.json") do
        content join!(
          "{\n",
          "  \"run_list\": [ \"",
          join!( ref!(:chef_run_list), { :options => { :delimiter => '", "'}}),
          "\" ]\n",
          "}\n"
        )
      end

      files("c:\\chef\\s3get.ps1") do
        content join!(
          "param(\n",
          "  [String] $bucketName,\n",
          "  [String] $key,\n",
          "  [String] $file\n",
          ")\n\n",

          "Import-Module \"c:\\program files (x86)\\aws tools\\powershell\\awspowershell\\awspowershell.psd1\"\n",
          "Read-S3Object -BucketName $bucketName -Key $key -File $file\n"
        )
      end

      files("c:\\chef\\wget.ps1") do
        content join!(
          "param(\n",
          "  [String] $remoteUrl,\n",
          "  [String] $localPath\n",
          ")\n\n",
          "try {\n",
          "  $webClient = new-object System.Net.WebClient\n",
          "  $webClient.DownloadFile($remoteUrl, $localPath)\n",
          "}\n",
          "catch {\n",
          "  write-output $_.Exception.Message\n",
          "}"
        )
      end

      files("c:\\chef\\ohai\\hints\\ec2.json") do
        content "{}"
      end

      commands "01-s3-download-validator-key" do
        command join!(
          "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -File",
          " c:\\chef\\s3get.ps1",
          " \"", ref!(:chef_validator_key_bucket), "\"",
          " \"/validation.pem\"",
          " \"c:\\chef\\validation.pem\""
        )
      end

      commands "02-get-encrypted-data-bag-secret" do
        command join!(
          "powershell.exe -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -File",
          " c:\\chef\\s3get.ps1",
          " \"", ref!(:chef_validator_key_bucket), "\"",
          " \"/encrypted_data_bag_secret\"",
          " \"c:\\chef\\encrypted_data_bag_secret\""
        )
      end

      commands "03-download-chef-client" do
        command %Q!powershell.exe -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -File c:\\chef\\wget.ps1 "https://www.opscode.com/chef/download?p=windows&pv=2008r2&m=x86_64&v=latest" "%TEMP%\\chef-client-latest.msi"!
      end

      commands "04-install-chef-client" do
        command %Q!msiexec /qn /log "%TEMP%\\chef-client-latest.log" /i "%TEMP%\\chef-client-latest.msi"!
      end

      commands "05-run-chef-client" do
        command join!(
          "SET \"PATH=%PATH%;c:\\ruby\\bin;c:\\opscode\\chef\\bin;c:\\opscode\\chef\\embedded\\bin\" &&",
          " c:\\opscode\\chef\\bin\\chef-client -E ", ref!(:chef_environment), " -j c:\\chef\\first-boot.json"
        )
      end
    end
  end
end