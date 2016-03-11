// Parameters: workflow_aws_region, workflow_aws_access_key_id, workflow_aws_secret_access_key

def workflow_env = 'recovery'

build job: '100-launch-vpc',
      parameters: [
        [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
        [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
        [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
        [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
        [$class: 'StringParameterValue', name: 'allow_ssh', value: '127.0.0.1/32']
      ]

parallel first: {
  build job: '110-launch-nexus-rds',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'TextParameterValue', name: 'instance_type', value: 'db.t2.small'],
          [$class: 'TextParameterValue', name: 'restore_rds_snapshot', value: 'indigo-prod-nexus']
        ]
}, second: {
  build job: '120-launch-elasticache',
  parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'TextParameterValue', name: 'instance_type', value: 'cache.t2.small']
        ]
}, third: {
  try {
    build job: '210-launch-vpn',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the vpn failed. ' + e // TODO: send notifications
  }
}, fourth: {
  try {
    build job: '220-launch-whatsinstalled',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching whatsinstalled failed. ' + e // TODO: send notifications
  }
}

parallel first: {
  build job: '320-launch-fileserver',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'c3.large'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '50'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}, second: {
  build job: '330-launch-rabbitmq',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'm3.large'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '20'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}, third: {
  build job: '340-launch-tokumx-replicaset',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'r3.xlarge'],
          [$class: 'StringParameterValue', name: 'restore_from_snapshot', value: 'true']
        ]
}

parallel first: {
  build job: '400-launch-assaymatic',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
          [$class: 'StringParameterValue', name: 'max_size', value: '2'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
        ]
}, second: {
  try {
    build job: '410-launch-nexus',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching nexus failed.' // TODO: send notifications
  }
}

parallel first: {
  try {
    build job: '500-launch-compute-servers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '5'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '5']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the site manager failed.'
  }
}, second: {
  build job: '510-launch-quartermasters',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
          [$class: 'StringParameterValue', name: 'max_size', value: '2'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
        ]
}, third: {
  try {
    build job: '520-launch-housekeepers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
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
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '5'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '5']
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
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
            [$class: 'StringParameterValue', name: 'max_size', value: '1'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the purgery server failed.'
  }
}, sixth: {
  try {
    build job: '541-launch-squabblers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
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
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the cbs reporter failed.'
  }
},  eighth: {
  try {
    build job: '542-launch-cbs-reporters',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
          ]
  } catch (Exception e) {
  echo 'Whoops.  Launching the cbs reporter failed.'
  }
}, ninth: {
  try {
    build job: '543-launch-batch-extractors',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 'm4.large'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the batch extractors failed.'
  }
}, tenth: {
  try {
    build job: '550-launch-reporters',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 'm3.large'],
            [$class: 'StringParameterValue', name: 'max_size', value: '7'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '7']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the reporters failed.'
  }
}, eleventh: {
  try {
    build job: '551-launch-reportcatchers',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 't2.large'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the reporter failed.'
  }
}, twelfth: {
  build job: '560-launch-custom-reports',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
          [$class: 'StringParameterValue', name: 'max_size', value: '3'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '3']
        ]
}, thirteenth: {
  build job: '561-launch-webservers',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
          [$class: 'StringParameterValue', name: 'max_size', value: '5'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '5']
        ]
}

build job: '600-launch-nginx',
      parameters: [
        [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
        [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
        [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
        [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
        [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
        [$class: 'StringParameterValue', name: 'max_size', value: '2'],
        [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
      ]
