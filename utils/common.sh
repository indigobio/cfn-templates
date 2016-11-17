#!/usr/bin/env bash

case $environment in
'ascent30'|'prod')
  export cert='arn:aws:iam::294091367658:server-certificate/poweredbyascent.net'
  export public_domain='poweredbyascent.net'
  export allowed_cidr='10.120.12.0/24'
  case $AWS_DEFAULT_REGION in
    'us-east-1')
      export cidr=19
    ;;
    'us-west-1')
      export cidr=28
    ;;
    'us-west-2')
      export cidr=24
    ;;
  esac
  ;;
'preview')
  export cert='arn:aws:iam::294091367658:server-certificate/poweredbyascent.net'
  export public_domain='ascentpreview.net'
  export allowed_cidr='10.120.12.0/24'
  case $AWS_DEFAULT_REGION in
    'us-east-1')
      export cidr=23
    ;;
    'us-west-1')
      export cidr=27
    ;;
    'us-west-2')
      export cidr=31
    ;;
  esac
  ;;
'qa1')
  export cert='arn:aws:iam::155531623723:server-certificate/ascentundertest.net'
  export public_domain='ascentundertest.net'
  export allowed_cidr='10.120.18.0/24'
  case $AWS_DEFAULT_REGION in
    'us-east-1')
      export cidr=20
    ;;
    'us-west-1')
      export cidr=29
    ;;
    'us-west-2')
      export cidr=25
    ;;
  esac
  ;;
'qa2')
  export cert='arn:aws:acm:us-east-1:155531623723:certificate/5e9405b5-ce69-44ec-b3b8-e919a7844a0d'
  export public_domain='ascentquality.net'
  export allowed_cidr='10.250.216.0/24'
  case $AWS_DEFAULT_REGION in
    'us-east-1')
      export cidr=21
    ;;
    'us-west-1')
      export cidr=30
    ;;
    'us-west-2')
      export cidr=26
    ;;
  esac
  ;;
'research')
  export cert='arn:aws:iam::155531623723:server-certificate/indigoresearch.net-2015-12-07'
  export public_domain='indigoresearch.net'
  case $AWS_DEFAULT_REGION in
    'us-east-1')
      export cidr=23
    ;;
    'us-west-1')
      export cidr=30
    ;;
    'us-west-2')
      export cidr=26
    ;;
  esac
  ;;
'dr')
  export cert='arn:aws:iam::294091367658:server-certificate/ascentrecovery.net'
  export public_domain='ascentrecovery.net'
  case $AWS_DEFAULT_REGION in
    'us-east-1')
      export cidr=23
    ;;
    'us-west-1')
      export cidr=31
    ;;
    'us-west-2')
      export cidr=27
    ;;
  esac
  ;;
'recovery')
  export cert='arn:aws:iam::294091367658:server-certificate/ascentrecovered.net'
  export public_domain='ascentrecovered.net'
  case $AWS_DEFAULT_REGION in
    'us-east-1')
      export cidr=23
    ;;
    'us-west-1')
      export cidr=31
    ;;
    'us-west-2')
      export cidr=27
    ;;
  esac
  ;;
esac

export lb_name=indigo-${environment}-public-elb-${BUILD_NUMBER}
export private_domain=${environment}.indigo
