SparkleFormation.dynamic(:readonly_rds_db_instance) do |_name, _config = {}|

  # {
  #   "Type": "AWS::RDS::DBInstance",
  #   "Properties": {
  #     "AllocatedStorage" : String,
  #     "AllowMajorVersionUpgrade" : Boolean,
  #     "AutoMinorVersionUpgrade" : Boolean,
  #     "AvailabilityZone" : String,
  #     "BackupRetentionPeriod" : String,
  #     "CharacterSetName" : String,
  #     "DBInstanceClass" : String,
  #     "DBInstanceIdentifier" : String,
  #     "DBName" : String,
  #     "DBParameterGroupName" : String,
  #     "DBSecurityGroups" : [ String, ... ],
  #     "DBSnapshotIdentifier" : String,
  #     "DBSubnetGroupName" : String,
  #     "Engine" : String,
  #     "EngineVersion" : String,
  #     "Iops" : Number,
  #     "KmsKeyId" : String,
  #     "LicenseModel" : String,
  #     "MasterUsername" : String,
  #     "MasterUserPassword" : String,
  #     "MultiAZ" : Boolean,
  #     "OptionGroupName" : String,
  #     "Port" : String,
  #     "PreferredBackupWindow" : String,
  #     "PreferredMaintenanceWindow" : String,
  #     "PubliclyAccessible" : Boolean,
  #     "SourceDBInstanceIdentifier" : String,
  #     "StorageEncrypted" : Boolean,
  #     "StorageType" : String,
  #     "Tags" : [ Resource Tag, ..., ],
  #     "VPCSecurityGroups" : [ String, ... ]
  #   }
  # }

  parameters("#{_name}_allocated_storage".to_sym) do
    type 'Number'
    min_value _config.fetch(:allocated_storage, 10)
    default _config.fetch(:allocated_storage, 10)
    description "The amount of allcoated storage for the #{_name} database instance"
    constraint_description "Must be a number #{_config.fetch(:allocated_storage, 100)} or higher"
  end

  parameters("#{_name}_allow_major_version_upgrade".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:allow_major_version_upgrade, 'false').to_s
    description 'Allow major database version upgrades during maintenance'
  end

  parameters("#{_name}_auto_minor_version_upgrade".to_sym) do
    type 'String'
    allowed_values %w(true false)
    default _config.fetch(:auto_minor_version_upgrade, 'false').to_s
    description 'Automatically apply minor database version upgrades during maintenance'
  end

  parameters("#{_name}_d_b_instance_class".to_sym) do
    type 'String'
    allowed_values %w( db.t1.micro db.m1.small db.m1.medium db.m1.large db.m1.xlarge db.m2.xlarge
                       db.m2.2xlarge db.m2.4xlarge db.m3.medium db.m3.large db.m3.xlarge db.m3.2xlarge
                       db.r3.large db.r3.xlarge db.r3.2xlarge db.r3.4xlarge db.r3.8xlarge db.t2.micro
                       db.t2.small db.t2.medium )
    default _config.fetch(:db_instance_class, 'db.t2.micro')
    description "Instance types to run the #{_name} database instance"
  end

  parameters("#{_name}_d_b_instance_identifier".to_sym) do
    type 'String'
    default "#{ENV['org']}-#{ENV['environment']}-#{_name}"
    allowed_pattern "[\\x20-\\x7E]*"
    description "RDS instance identifier"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_engine".to_sym) do
    type 'String'
    allowed_values %w( MySQL oracle-ee sqlserver-se sqlserver-ex sqlserver-web postgres )
    default _config.fetch(:engine, 'postgres')
    description "Database engine for the #{_name} database instance"
  end

  parameters("#{_name}_storage_encrypted".to_sym) do
    type 'String'
    default _config.fetch(:storage_encrypted, 'true')
    allowed_values %w(true false)
    description 'Encrypt storage'
  end

  resources "#{_name}_rds_db_instance" do
    type 'AWS::RDS::DBInstance'
    properties do
      allocated_storage ref!("#{_name}_allocated_storage".to_sym)
      allow_major_version_upgrade ref!("#{_name}_allow_major_version_upgrade".to_sym)
      auto_minor_version_upgrade ref!("#{_name}_auto_minor_version_upgrade".to_sym)
      d_b_instance_class ref!("#{_name}_d_b_instance_class".to_sym)
      d_b_instance_identifier ref!("#{_name}_d_b_instance_identifier".to_sym)
      if _config.has_key?(:db_parameter_group)
        d_b_parameter_group_name ref!(_config[:db_parameter_group])
      end
      source_d_b_instance_identifier join!(['arn:aws:rds', region!, account_id!, 'db', ref!(_config[:source_db_instance_identifier])], {:options => { :delimiter => ':'}})
      v_p_c_security_groups _config[:vpc_security_groups]
      d_b_subnet_group_name ref!(_config[:db_subnet_group])
      engine ref!("#{_name}_engine".to_sym)
      engine_version map!(:engine_to_latest_version, ref!("#{_name}_engine".to_sym), 'version')
      storage_encrypted ref!("#{_name}_storage_encrypted".to_sym)
      if _config.fetch(:publicly_accessible, false)
        publicly_accessible 'true'
      end
      tags _array(
        -> {
          key 'Environment'
          value ENV['environment']
        }
      )
    end
  end

  outputs do
    endpoint_address do
      value attr!("#{_name}_rds_db_instance".to_sym, 'Endpoint.Address')
      description "Address of #{_name} RDS Database Instance"
    end
  end

end

