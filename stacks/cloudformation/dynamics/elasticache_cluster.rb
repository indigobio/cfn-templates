SparkleFormation.dynamic(:elasticache_cluster) do | _name, _config = {} |

  # {
  #   "Type" : "AWS::ElastiCache::CacheCluster",
  #   "Properties" : {
  #     "AutoMinorVersionUpgrade" : Boolean,
  #     "AZMode" : String,
  #     "CacheNodeType" : String,
  #     "CacheParameterGroupName" : String,
  #     "CacheSecurityGroupNames" : [ String, ... ],
  #     "CacheSubnetGroupName" : String,
  #     "ClusterName" : String,
  #     "Engine" : String,
  #     "EngineVersion" : String,
  #     "NotificationTopicArn" : String,
  #     "NumCacheNodes" : String,
  #     "Port" : Integer,
  #     "PreferredAvailabilityZone" : String,
  #     "PreferredAvailabilityZones" : [String, ... ],
  #     "PreferredMaintenanceWindow" : String,
  #     "SnapshotArns" : [String, ... ],
  #     "SnapshotName" : String,
  #     "SnapshotRetentionLimit" : Integer,
  #     "SnapshotWindow" : String,
  #     "Tags" : [Resource Tag, ...],
  #     "VpcSecurityGroupIds" : [String, ...]
  #   }
  # }

  # "SubnetGroup" : {
  #   "Type" : "AWS::ElastiCache::SubnetGroup",
  #   "Properties" : {
  #     "Description" : String,
  #     "SubnetIds" : [ String, ... ]
  #   }
  # }

  # memcached only, sorry.

  _config[:nodes] ||= 2

  parameters("#{_name}_instance_type".to_sym) do
    type 'String'
    allowed_values %w(cache.t2.micro cache.t2.small cache.t2.medium cache.m3.medium cache.m3.large cache.m3.xlarge cache.m3.2xlarge)
    default _config[:instance_type] || 'cache.t2.small'
    description 'Instance type to use for cluster members'
  end

  parameters("#{_name}_memcached_port".to_sym) do
    type 'Number'
    min_value '1025'
    max_value '65535'
    default _config[:port] || '11311'
  end

  resources("#{_name}_subnet_group".to_sym) do
    type 'AWS::ElastiCache::SubnetGroup'
    properties do
      description 'Default subnet group'
      subnetIds _config[:subnets]
    end
  end

  resources("#{_name}_elasticache_cluster".to_sym) do
    type 'AWS::ElastiCache::CacheCluster'
    properties do
      cache_node_type ref!("#{_name}_instance_type".to_sym)
      engine 'memcached'
      port ref!("#{_name}_memcached_port".to_sym)
      num_cache_nodes _config[:nodes]
      vpc_security_group_ids _config[:security_groups]
      cache_subnet_group_name ref!("#{_name}_subnet_group".to_sym)
      if _config[:nodes].to_i > 1
        a_z_mode 'cross-az'
        preferred_availability_zones *_config[:nodes].to_i.downto(1).map { |i| select!(i, get_azs!) }
      else
        a_z_mode 'single-az'
      end
      tags _array(
        -> {
          key 'Name'
          value "#{_name}_elasticache_cluster".gsub('-','_').to_sym
        },
        -> {
          key 'Environment'
          value ENV['environment']
        }
      )
    end
  end
end