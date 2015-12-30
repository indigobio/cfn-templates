SparkleFormation.new('empire') do
  dynamic!(:ecs_task_definition, 'empire',
           :container_definitions => [
             {
               :name => 'test',
               :command => ['echo', 'hello'],
               :cpu => '1',
               :entrypoint => [ '/bin/bash', '-c' ],
               :image => 'ubuntu/14.04',
               :environment => [ { :name => 'test', :value => 'test'}, { :name => 'test2', :value => 'test2' } ],
               :memory => 256,
               :essential => false,
               :port_mappings => [ { :container_port => '8080', :host_port => '8080' } ],
               :volumes_from => [ { :source_container => 'test' } ],
               :mount_points => [ { :container_path => '/test', :source_volume => '/test', :read_only => true} ]
             }
            ],
          :volume_definitions => [
              {
                :name => 'test1',
                :source_path => '/test1'
              },
              {
                :name => 'test2',
                :source_path => '/test2'
              }
            ]
          )
end