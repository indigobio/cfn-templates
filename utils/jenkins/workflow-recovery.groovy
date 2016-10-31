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
          [$class: 'TextParameterValue', name: 'instance_type', value: 'db.t2.medium'],
          [$class: 'TextParameterValue', name: 'restore_rds_snapshot', value: 'indigo-prod-nexus']
        ]
}, second: {
  build job: '111-launch-empire-rds',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'TextParameterValue', name: 'instance_type', value: 'db.t2.small']
        ]
}, third: {
  build job: '111-launch-chronicle-rds',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'TextParameterValue', name: 'instance_type', value: 'db.m3.large'],
    [$class: 'TextParameterValue', name: 'restore_rds_snapshot', value: 'indigo-prod-nexus']
  ]
}

{
  try {
  build job: '130-launch-cloudfront',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key]
        ]
  } catch (Exception e) {
    echo 'Whoops.  Launching the vpn failed. ' + e // TODO: send notifications
  }
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
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium']
        ]
} second: {
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

parallel first:
{
  build job: '530-launch-mzconvert',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'c4.large'],
          [$class: 'StringParameterValue', name: 'max_size', value: '5'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '5']
        ]
}, second: {
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
}, third: {
  build job: '601-launch-empire',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'c4.large'],
          [$class: 'StringParameterValue', name: 'max_size', value: '5'],
          [$class: 'StringParameterValue', name: 'desired_capacity', value: '5']
        ]
}