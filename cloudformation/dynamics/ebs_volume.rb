SparkleFormation.dynamic(:ebs_volume) do |_name, _config|
  # _config[:instance] must be supplied.

  parameters("#{_name}_ebs_volume_size".to_sym) do
    type 'Number'
    min_value '1'
    max_value '1000'
    default _config[:size] || '100'
  end

  parameters("#{_name}_ebs_volume_type".to_sym) do
    type 'String'
    allowed_values _array('standard', 'gp2', 'io1')
    default _config[:volume_type] || 'gp2'
    description 'Magnetic (standard), General Purpose (gp2), or Provisioned IOPS (io1)'
  end

  parameters("#{_name}_ebs_provisioned_iops".to_sym) do
    type 'Number'
    min_value '1'
    max_value '4000'
    default _config[:piops] || (_config[:size].to_i * 3 || 300)
  end

  parameters("#{_name}_ebs_snapshot_id".to_sym) do
    type 'String'
    allowed_pattern "snap-[\da-f]{8}|none"
    default _config[:snapshot_id] || 'none'
    description 'Snapshot from which to create EBS volume'
  end

  resources("#{_name}_ebs_volume".to_sym) do
    type 'AWS::EC2::Volume'
    properties do
      availability_zone attr!(_config[:instance], :availability_zone)
      volume_type ref!("#{_name}_ebs_volume_type".to_sym)
      snapshot_id if!(equals!(ref!("#{_name}_ebs_snapshot_id".to_sym), 'none'), ref!('AWS::NoValue'), ref!("#{_name}_ebs_snapshot_id".to_sym))
      iops if!(equals!(ref!("#{_name}_ebs_volume_type".to_sym), 'io1'), ref!("#{_name}_ebs_provisioned_iops".to_sym), ref!('AWS::NoValue'))
      size ref!("#{_name}_ebs_volume_size".to_sym)
    end
  end
end