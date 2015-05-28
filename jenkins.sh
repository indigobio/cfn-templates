#!/bin/bash -e

export BUILD_NUMBER=${BUILD_NUMBER:=`date '+%Y%m%d%H%M'`}
export region=${region:='us-west-2'}
export environment=${environment:='dr'}

# Yes, the two things this script does could be put into functions.  I keep hitting corner cases
# and punting.  I'd rather just set up Jenkins build pipelines composed of individual jobs.

cd vpc
mkdir -p cloudformation/output
backup_id=$backup environment=${environment} region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/vpc.rb cloudformation/output/vpc-${environment}_${region}.json
cd ..

bundle exec sfn create -f vpc/cloudformation/output/vpc-${environment}-${region}.json \
  -r ElbSslCertificateId:arn:aws:iam::294091367658:server-certificate/ascentrecovery.net \
  -r PublicElbRecord:${region}.ascentrecovery.net -d indigo-${environment}-vpc-${region}-${BUILD_NUMBER}

backup=$(bundle exec ruby find-backup-ids.rb -r $region -l)

cd stacks
mkdir -p cloudformation/output
backup_id=$backup environment=${environment} region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/databases.rb cloudformation/output/databases_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/databases_${environment}_${region}.json \
  -r DatabaseInstancesEbsOptimized:true \
  -r DatabaseInstanceType:m3.xlarge \
  -r ThirddatabaseInstancesEbsOptimized:true \
  -r ThirddatabaseInstanceType:m3.xlarge -d indigo-${environment}-tokumx-${region}-${BUILD_NUMBER}

bundle install

cd stacks
mkdir -p cloudformation/output
bundle exec ruby ../sfcompile.rb cloudformation/templates/vpn.rb cloudformation/output/vpn_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/vpn_${environment}_${region}.json \
  -r VpnInstanceType:t2.micro -d indigo-${environment}-vpn-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
bundle exec ruby ../sfcompile.rb cloudformation/templates/logstash.rb cloudformation/output/logstash_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/logstash_${environment}_${region}.json \
  -r LogstashEbsVolumeSize:25 \
  -r LogstashInstanceType:m3.large -d indigo-${environment}-logstash-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/rabbitmq.rb cloudformation/output/rabbitmq_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/rabbitmq_${environment}_${region}.json \
  -r RabbitmqEbsVolumeSize:20 \
  -r RabbitmqInstanceType:r3.large -d indigo-${environment}-rabbitmq-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/logstash.rb cloudformation/output/logstash_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/logstash_${environment}_${region}.json \
  -r LogstashEbsVolumeSize:25 \
  -r LogstashInstanceType:m3.large -d indigo-${environment}-logstash-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/fileserver.rb cloudformation/output/fileserver_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/fileserver_${environment}_${region}.json \
  -r FileserverEbsVolumeSize:50 -d indigo-${environment}-fileserver-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/assaymatic.rb cloudformation/output/assaymatic_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/assaymatic_${environment}_${region}.json \
  -d indigo-${environment}-assaymatic-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/quartermasters.rb cloudformation/output/quartermasters_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/quartermasters_${environment}_${region}.json \
  -d indigo-${environment}-quartermasters-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/housekeepers.rb cloudformation/output/housekeepers_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/housekeepers_${environment}_${region}.json \
  -d indigo-${environment}-housekeepers-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/compute.rb cloudformation/output/compute_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/compute_${environment}_${region}.json \
  -r ComputeMaxSize:5 \
  -r ComputeDesiredCapacity:5 -d indigo-${environment}-compute-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/webservers.rb cloudformation/output/webservers_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/webservers_${environment}_${region}.json \
  -r WebserverInstanceType:t2.small \
  -r WebserverMaxSize:5 \
  -r WebserverDesiredCapacity:5 -d indigo-${environment}-webservers-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/webservers.rb cloudformation/output/webservers_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/webservers_${environment}_${region}.json \
  -r WebserverInstanceType:t2.small \
  -r WebserverMaxSize:5 \
  -r WebserverDesiredCapacity:5 -d indigo-${environment}-webservers-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/daemons.rb cloudformation/output/daemons_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/daemons_${environment}_${region}.json \
  -r ReporterInstanceType:m3.medium \
  -r ReporterMaxSize:2 \
  -r ReporterDesiredCapacity:2 \
  -r CustomreportsInstanceType:t2.small \
  -r CustomreportsMaxSize:2 \
  -r CustomreportsDesiredCapacity:2 \
  -r PurgeryInstanceType:t2.small \
  -r PurgeryMinSize:0 \
  -r PurgeryMaxSize:1 \
  -r PurgeryDesiredCapacity:1 \
  -r CbsInstanceType:t2.small \
  -r CbsMaxSize:1 \
  -r CbsDesiredCapacity:1 \
  -r CorrelatorInstanceType:t2.small \
  -r CorrelatorMaxSize:1 \
  -r CorrelatorDesiredCapacity:1 \
  -d indigo-${environment}-daemons-${region}-${BUILD_NUMBER}

cd stacks
mkdir -p cloudformation/output
environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
  cloudformation/templates/nginx.rb cloudformation/output/nginx_${environment}_${region}.json
cd ..

bundle exec sfn create -f stacks/cloudformation/output/nginx_${environment}_${region}.json \
  -d indigo-${environment}-nginx-${region}-${BUILD_NUMBER}
