// Parameter: workflow_aws_region

def workflow_env = 'research'

build job: '100-launch-vpc',
      parameters: [
        [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
        [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
        [$class: 'StringParameterValue', name: 'allow_ssh', value: '207.250.246.0/24']
      ]

parallel first: {
  build job: '110-launch-nexus-rds',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'TextParameterValue', name: 'instance_type', value: 'db.t2.micro']
        ]
}, second: {
  try {
    build job: '210-launch-vpn',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the vpn failed.' // TODO: send notifications
  }
}

parallel first: {
  build job: '300-launch-couchbase',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro']
        ]
}, second: {
  build job: '320-launch-fileserver',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '10'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}, third: {
  build job: '330-launch-rabbitmq',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '10'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}, fourth: {
  build job: '341-launch-tokumx-single',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'm4.large'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '20'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}

parallel first: {
  build job: '400-launch-assaymatic',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
          [$class: 'StringParameterValue', name: 'max_size', value: '1'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
        ]
}, second: {
  try {
    build job: '410-launch-site-manager',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
  } catch (Exception e) {
    echo 'Whoops.  Launching the site manager failed.' // TODO: send notifications
  }
}

parallel first: {
  try {
    build job: '500-launch-compute-servers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the site manager failed.'
  }
}, second: {
  build job: '510-launch-quartermasters',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
          [$class: 'StringParameterValue', name: 'max_size', value: '1'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
        ]
}, third: {
  try {
    build job: '520-launch-housekeepers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the housekeeper failed.'
  }
}, fourth: {
  try {
    build job: '530-launch-mzconvert',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the mzconverter failed.'
  }
}, fifth: {
  try {
    build job: '540-launch-purgery',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the purgery serve failed.'
  }
}, sixth: {
  try {
    build job: '541-launch-squabblers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the squabbler failed.'
  }
}, seventh: {
  try {
    build job: '542-launch-cbs-reporters',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the cbs reporter failed.'
  }
}, eighth: {
  try {
    build job: '550-launch-reporters',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the reporter failed.'
  }
}, ninth: {
  try {
    build job: '551-launch-reportcatchers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the reporter failed.'
  }
}, tenth: {
  build job: '560-launch-custom-reports',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
          [$class: 'StringParameterValue', name: 'max_size', value: '1'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
        ]
}, eleventh: {
  build job: '561-launch-webservers',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
          [$class: 'StringParameterValue', name: 'max_size', value: '1'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
        ]
}

build job: '600-launch-nginx',
      parameters: [
        [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
        [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
        [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
        [$class: 'StringParameterValue', name: 'max_size', value: '1'],
        [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
      ]
