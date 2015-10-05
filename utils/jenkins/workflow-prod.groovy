// Parameters: workflow_aws_region, workflow_aws_access_key_id, workflow_aws_secret_access_key

def workflow_env = 'prod'

build job: '100-launch-vpc',
parameters: [
  [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
  [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
  [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
  [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
  [$class: 'StringParameterValue', name: 'allow_ssh', value: '207.250.246.0/24']
]

parallel first: {
  build job: '110-launch-nexus-rds',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'TextParameterValue', name: 'instance_type', value: 'db.t2.micro']
  ]
}, second: {
  build job: '200-launch-logstash',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'TextParameterValue', name: 'instance_type', value: 't2.large'],
    [$class: 'TextParameterValue', name: 'volume_size', value: '25']
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
}

parallel first: {
  build job: '300-launch-couchbase',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'm3.medium']
        ]
}, second: {
  build job: '320-launch-fileserver',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '20'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}, third: {
  build job: '330-launch-rabbitmq',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'm3.large'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '10'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}, fourth: {
  build job: '340-launch-tokumx-replicaset',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'r3.4xlarge'],
          [$class: 'StringParameterValue', name: 'restore_from_snapshot', value: 'true']
        ]
}

build job: '400-launch-assaymatic',
      parameters: [
        [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
        [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
        [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
        [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
        [$class: 'StringParameterValue', name: 'instance_type', value: 'c3.xlarge'],
        [$class: 'StringParameterValue', name: 'max_size', value: '2'],
        [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
      ]


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
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
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
}, eighth: {
  try {
    build job: '550-launch-reporters',
          parameters: [
            [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
            [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 'm3.large'],
            [$class: 'StringParameterValue', name: 'max_size', value: '10'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '10']
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
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
            [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
            [$class: 'StringParameterValue', name: 'instance_type', value: 'm3.large'],
            [$class: 'StringParameterValue', name: 'max_size', value: '2'],
            [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
          ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the reporter failed.'
  }
}, tenth: {
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
}, eleventh: {
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

try {
  build job: '410-launch-site-manager',
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
  echo 'Whoops.  Launching the site manager failed.' // TODO: send notifications
}