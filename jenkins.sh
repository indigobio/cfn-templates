#!/bin/bash -e

export BUILD_NUMBER=${BUILD_NUMBER:=`date '+%Y%m%d%H%M'`}
export region=${region:='us-west-2'}
export environment=${environment:='dr'}

function announce() {
  msg="$*"
  len=${#msg}

  echo; eval printf '=%.0s' {1..$len}; echo
  echo $msg
  eval printf '=%.0s' {1..$len}; echo; echo
}

function build_template() {
  type=$1; shift;
  template=$1; shift;
  args=$*

  cd $type
  mkdir -p cloudformation/output
  $args environment=$environment region=$region bundle exec ruby ../sfcompile.rb \
    cloudformation/templates/$template cloudformation/output/${template}-${environment}_${region}.json
  cd ..
}

function launch_stack() {
  type=$1; shift;
  template=$1; shift;
  args=$*

  bundle exec sfn create -f ${type}/cloudformation/output/${template}-${environment}_${region}.json \
  $args \
  -d indigo-${environment}-${template}-${region}-${BUILD_NUMBER}
}

announce building and launching vpc
build_template vpc vpc
launch_stack vpc vpc -r ElbSslCertificateId:arn:aws:iam::294091367658:server-certificate/ascentrecovery.net \
  -r PublicElbRecord:\*.ascentrecovery.net

announce building and launching databases
backup=$(bundle exec ruby find-backup-ids.rb -r $region -l)
build_template stacks databases backup_id=${backup}
launch_stack stacks databases -r DatabaseInstancesEbsOptimized:true -r DatabaseInstanceType:m3.xlarge \
  -r ThirddatabaseInstancesEbsOptimized:true -r ThirddatabaseInstanceType:m3.xlarge

announce building and launching vpn
build_template stacks vpn
launch_stack stacks vpn -r VpnInstanceType:t2.micro

announce building and launching logstash
build_template stacks logstash
launch_stack stacks logstash -r LogstashEbsVolumeSize:25 -r LogstashInstanceType:m3.large

announce building and launching rabbitmq
build_template stacks rabbitmq
launch_stack stacks rabbitmq -r RabbitmqEbsVolumeSize:20 -r RabbitmqInstanceType:r3.large

announce building and launching fileserver
build_template stacks fileserver
launch_stack stacks fileserver -r FileserverEbsVolumeSize:50

announce building and launching assaymatic
build_template stacks assaymatic
launch_stack stacks assaymatic -r AssaymaticMaxSize:2 -r AssaymaticDesiredCapacity:2

announce building and launching quartermasters
build_template stacks quartermasters
launch_stack stacks quartermasters -r QuartermasterMaxSize:2 -r QuartermasterDesiredCapacity:2

announce building and launching housekeepers
build_template stacks housekeepers
launch_stack stacks housekeepers -r HousekeeperMaxSize:2 -r HousekeeperDesiredCapacity:2

announce building and launching compute
build_template stacks compute
launch_stack stacks compute -r ComputeMaxSize:2 -r ComputeDesiredCapacity:2

announce building and launching webservers
build_template stacks webservers
launch_stack stacks webservers -r WebserverMaxSize:2 -r WebserverDesiredCapacity:2

announce building and launching daemons
build_template stacks daemons
launch_stack stacks daemons

announce building and launching reporters
build_template stacks reporters
launch_stack stacks reporters

announce building and launching nginx
build_template stacks nginx
launch_stack stacks nginx -r NginxMaxSize:2 -r NginxDesiredCapacity:2