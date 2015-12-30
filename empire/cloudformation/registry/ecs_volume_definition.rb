SfnRegistry.register(:ecs_volume_definition) do |_config = {}|

  # "VolumeDefinitions": {
  #   "Name" : String,
  #   "Host" : Host
  # }

  # "Host": {
  #  "SourcePath" : String
  # }

  _config[:name]        ||= 'default'
  _config[:source_path] ||= ''

  options = Hash.new

  if !_config[:source_path].empty?
    options['Host'] = {
      'SourcePath' => _config[:source_path]
    }
  end

  volume_definition = {
    'Name' => _config[:name]
  }

  volume_definition.merge(options)

end