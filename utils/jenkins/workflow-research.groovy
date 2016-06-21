// Parameter: workflow_aws_region

def workflow_env = 'research'

build job: '100-launch-vpc',
parameters: [
  [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
  [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
  [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
  [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
  [$class: 'StringParameterValue', name: 'allow_ssh', value: '127.0.0.1/32']
]

parallel first: {
  build job: '101-launch-buckets',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key]
  ]
}, second: {
  build job: '130-launch-cloudfront',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key]
  ]
}

parallel first: {
  build job: '110-launch-nexus-rds',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'TextParameterValue', name: 'instance_type', value: 'db.t2.micro' ]
  ]
}, second: {
  build job: '111-launch-empire-rds',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'TextParameterValue', name: 'instance_type', value: 'db.t2.micro' ]
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
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro']
        ]
}, second: {
  build job: '330-launch-rabbitmq',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 't2.micro'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '10'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}, fourth: {
  build job: '341-launch-tokumx-single',
        parameters: [
          [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
          [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
          [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
          [$class: 'StringParameterValue', name: 'instance_type', value: 'm4.large'],
          [$class: 'StringParameterValue', name: 'restore_from_snapshot', value: 'false'],
          [$class: 'StringParameterValue', name: 'volume_size', value: '20'],
          [$class: 'StringParameterValue', name: 'volume_count', value: '2']
        ]
}

parallel first: {
  build job: '530-launch-mzconvert',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'StringParameterValue', name: 'instance_type', value: 't2.medium'],
    [$class: 'StringParameterValue', name: 'max_size', value: '1'],
    [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
  ]
}, second: {
  build job: '600-launch-nginx',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'StringParameterValue', name: 'instance_type', value: 't2.small'],
    [$class: 'StringParameterValue', name: 'max_size', value: '1'],
    [$class: 'StringParameterValue', name: 'desired_capacity', value: '1']
  ]
}, third: {
  build job: '601-launch-empire',
  parameters: [
    [$class: 'TextParameterValue', name: 'environment', value: workflow_env],
    [$class: 'TextParameterValue', name: 'region', value: workflow_aws_region],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_access_key_id', value: workflow_aws_access_key_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'workflow_aws_secret_access_key', value: workflow_aws_secret_access_key],
    [$class: 'CredentialsParameterValue', description: '', name: 'github_id', value: workflow_empire_github_id],
    [$class: 'CredentialsParameterValue', description: '', name: 'github_secret', value: workflow_empire_github_secret],
    [$class: 'StringParameterValue', name: 'github_org', value: workflow_empire_github_org],
    [$class: 'StringParameterValue', name: 'minion_max_size', value: '3'],
    [$class: 'StringParameterValue', name: 'minion_desired_capacity', value: '3'],
    [$class: 'StringParameterValue', name: 'minion_instance_type', value: 'c4.xlarge'],
    [$class: 'StringParameterValue', name: 'minion_ebs_volume_size', value: '100'],
    [$class: 'StringParameterValue', name: 'minion_ebs_swap_size', value: '15'],
    [$class: 'StringParameterValue', name: 'controller_ebs_volume_size', value: '100'],
    [$class: 'StringParameterValue', name: 'desired_capacity', value: '2']
  ]
}
