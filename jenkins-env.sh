case $environment in
'ascent30'|'prod')
  export cert='arn:aws:iam::294091367658:server-certificate/poweredbyascent.net'
  export domain='poweredbyascent.net'
  export allowed_cidr='10.120.12.0/24'
  ;;
'qa1')
  export cert='arn:aws:iam::294091367658:server-certificate/ascentundertest.net'
  export domain='ascentundertest.net'
  export allowed_cidr='10.120.18.0/24'
  ;;
'qa2')
  export cert='arn:aws:iam::294091367658:server-certificate/ascentquality.net'
  export domain='ascentquality.net'
  export allowed_cidr='10.250.216.0/24'
  ;;
'research')
  export cert='arn:aws:iam::294091367658:server-certificate/indigoresearch.net'
  export domain='indigoresearch.net'
  ;;
'dr')
  export cert='arn:aws:iam::294091367658:server-certificate/ascentrecovery.net'
  export domain='ascentrecovery.net'
  ;;
esac


case $stack_size in
'demo')
  export nexus_db_instance_size='db.t2.micro'
  export vpn_instance_size='t2.micro'
  export logstash_instance_size='m4.large'
  ;;
'qa')
  export nexus_db_instance_size='db.t2.medium'
  export vpn_instance_size='t2.micro'
  export logstash_instance_size='m4.large'
  ;;
'production')
  export nexus_db_instance_size='db.m3.large'
  export vpn_instance_size='c4.large'
  export logstash_instance_size='r3.large'
  ;;
esac
