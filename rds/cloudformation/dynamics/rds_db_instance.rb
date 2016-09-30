SparkleFormation.dynamic(:rds_db_instance) do |_name, _config = {}|

  ENV['master_username']     ||= 'root'
  ENV['master_password']     ||= 'Wh00p_Wh00p!' # <---- must be longer than 8 characters

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

  parameters("#{_name}_backup_retention_period".to_sym) do
    type 'Number'
    min_value _config.fetch(:backup_retention_period, 1)
    default _config.fetch(:backup_retention_period, 7)
    description "Number of days to keep backups of the #{_name} database instance"
    constraint_description "Must be a number #{_config.fetch(:backup_retention_period, 1)} or higher"
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

  parameters("#{_name}_d_b_name".to_sym) do
    type 'String'
    default _name
    allowed_pattern "[\\x20-\\x7E]*"
    description "Name of the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_engine".to_sym) do
    type 'String'
    allowed_values %w( MySQL oracle-ee sqlserver-se sqlserver-ex sqlserver-web postgres )
    default _config.fetch(:engine, 'postgres')
    description "Database engine for the #{_name} database instance"
  end

  parameters("#{_name}_master_username".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default ENV['master_username']
    description "Master username for the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_master_password".to_sym) do
    type 'String'
    allowed_pattern "[\\x20-\\x7E]*"
    default ENV['master_password']
    description "Master password for the #{_name} database instance"
    constraint_description 'can only contain ASCII characters'
  end

  parameters("#{_name}_multi_a_z".to_sym) do
    type 'String'
    allowed_values %w( true false )
    default _config.fetch(:multi_az, 'true')
    description 'Set up a multi-AZ RDS instance'
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
      backup_retention_period ref!("#{_name}_backup_retention_period".to_sym)
      d_b_instance_class ref!("#{_name}_d_b_instance_class".to_sym)
      d_b_instance_identifier ref!("#{_name}_d_b_instance_identifier".to_sym)
      if _config.has_key?(:db_parameter_group)
        d_b_parameter_group_name ref!(_config[:db_parameter_group])
      end
      d_b_security_groups _config[:db_security_groups]
      d_b_subnet_group_name ref!(_config[:db_subnet_group])
      if _config.fetch(:db_snapshot_identifier, false)
        d_b_snapshot_identifier _config[:db_snapshot_identifier]
      else
        d_b_name ref!("#{_name}_d_b_name".to_sym)
        engine ref!("#{_name}_engine".to_sym)
        engine_version map!(:engine_to_latest_version, ref!("#{_name}_engine".to_sym), 'version')
        master_username ref!("#{_name}_master_username".to_sym)
        master_user_password ref!("#{_name}_master_password".to_sym)
        storage_encrypted ref!("#{_name}_storage_encrypted".to_sym)
      end
      multi_a_z ref!("#{_name}_multi_a_z".to_sym)
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

