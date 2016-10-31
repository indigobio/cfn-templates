current_dir = File.dirname(__FILE__)
log_level               :info
log_location            STDOUT
node_name               'lambda'
client_key              "#{current_dir}/lambda.pem"
chef_server_url         'https://api.chef.io/organizations/product_dev'
