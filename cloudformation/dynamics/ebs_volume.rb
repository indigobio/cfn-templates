SparkleFormation.dynamic(:ebs_volume) do |_name, _config = { :snapshot_id => 'none' }|
  # _config[:instance] must be supplied.

  conditions.set!(
    "#{_name}_is_from_snapshot".to_sym,
      not!(equals!(ref!("#{_name}_ebs_snapshot_id".to_sym), 'none'))
  )

  conditions.set!(
    "#{_name}_is_io1".to_sym,
      equals!(ref!("#{_name}_ebs_volume_type".to_sym), 'io1')
  )

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
    allowed_pattern "snap-[\\da-f]{8}|none"
    default _config[:snapshot_id] || 'none'
    description 'Snapshot from which to create EBS volume'
  end

  parameters("#{_name}_ebs_device_label") do
    type 'String'
    allowed_pattern "(\\/dev\\/sd|xvd)[f-z]+"
    default _config[:device] || '/dev/sdi'
    description 'The device label for the EBS volume (/dev/sdX)'
  end

  resources("#{_name}_ebs_volume".to_sym) do
    type 'AWS::EC2::Volume'
    properties do
      availability_zone attr!(_config[:instance], :availability_zone)
      volume_type ref!("#{_name}_ebs_volume_type".to_sym)
      snapshot_id if!("#{_name}_is_from_snapshot".to_sym, ref!("#{_name}_ebs_snapshot_id".to_sym), ref!('AWS::NoValue'))
      iops if!("#{_name}_is_io1".to_sym, ref!("#{_name}_ebs_provisioned_iops".to_sym), ref!('AWS::NoValue'))
      size ref!("#{_name}_ebs_volume_size".to_sym)
    end
  end

  # I feel like adding a volume attachment here is "mixing concerns" but then again
  # what's the point of re-importing instance ID, etc. to another dynamic?

  resources("#{_name}_ebs_volume_attachment".to_sym) do
    type 'AWS::EC2::VolumeAttachment'
    properties do
      device ref!("#{_name}_ebs_device_label".to_sym)
      instance_id ref!(_config[:instance])
      volume_id ref!("#{_name}_ebs_volume".to_sym)
    end
  end
end