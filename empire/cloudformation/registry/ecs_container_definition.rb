SfnRegistry.register(:ecs_container_definition) do |_config = {}|

  # "ContainerDefinitions": [ {
  #   "Command" : [ String, ... ],
  #   "Cpu" : Integer,
  #   "EntryPoint" : [ String, ... ],
  #   "Environment" : [ Environment Variable, ... ],
  #   "Essential" : Boolean,
  #   "Image" : String,
  #   "Links" : [ String, ... ],
  #   "Memory" : Integer,
  #   "MountPoints" : [ Mount Point, ... ],
  #   "Name" : String,
  #   "PortMappings" : [ Port Map, ... ],
  #   "VolumesFrom" : [ Volume From, ... ]
  # } ]

  # "MountPoints": [ {
  #   "ContainerPath" : String,
  #   "SourceVolume" : String,
  #   "ReadOnly" : Boolean
  # } ]

  # "PortMappings": [ {
  #   "ContainerPort" : Integer,
  #   "HostPort" : Integer
  # } ]

  # "VolumesFrom": [ {
  #   "SourceContainer" : String,
  #   "ReadOnly" : Boolean
  # } ]

  _config[:name]          ||= 'default'
  _config[:command]       ||= []
  _config[:entry_point]   ||= []
  _config[:cpu]           ||= ''
  _config[:environment]   ||= []
  _config[:essential]     ||= 'true'
  _config[:memory]        ||= '512'
  _config[:mount_points]  ||= []
  _config[:port_mappings] ||= []
  _config[:volumes_from]  ||= []
  _config[:links]         ||= []

  options = Hash.new

  if !_config[:command].empty?
    options['Command'] = _array(*_config[:command])
  end

  if !_config[:entry_point].empty?
    options['EntryPoint'] = _array(*_config[:entrypoint])
  end

  if !_config[:environment].empty?
    options['Environment'] = _array(
      *_config[:environment].map { |e| {
        'Name' => e[:name],
        'Value' => e[:value]
      }
    })
  end

  if !_config[:cpu].to_s.empty?
    options['Cpu'] = _config[:cpu].to_s
  end

  if !_config[:mount_points].empty?
    options['MountPoints'] = _array(
      *_config[:mount_points].map { |mp| {
        'ContainerPath' => mp[:container_path],
        'SourceVolume' => mp[:source_volume],
        'ReadOnly' => mp.fetch(:read_only, 'false').to_s
      }
    })
  end

  if !_config[:port_mappings].empty?
    options['PortMappings'] = _array(
      *_config[:port_mappings].map { |pm| {
        'ContainerPort' => pm[:container_port],
        'HostPort' => pm[:host_port]
      }
    })
  end

  if !_config[:volumes_from].empty?
    options['VolumesFrom'] = _array(
      *_config[:volumes_from].map { |vf| {
        'SourceContainer' => vf[:source_container],
        'ReadOnly' => vf.fetch(:read_only, 'false').to_s
      }
    })
  end

  if !_config[:links].empty?
    options['Links'] = _array(*_config[:links])
  end

  container_definition = {
    'Name' => _config[:name],
    'Image' => _config[:image],
    'Memory' => _config[:memory].to_s,
    'Essential' => _config[:essential].to_s
  }

  container_definition.merge(options)
end

