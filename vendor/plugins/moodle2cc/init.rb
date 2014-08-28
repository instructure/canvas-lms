Rails.configuration.to_prepare do

  Canvas::Plugin.register :moodle_converter, :export_system, {
          :name => proc { I18n.t(:m2c_name, 'Moodle Importer') },
          :author => 'Divergent Logic',
          :description => 'This enables importing Moodle 1.9 and 2.x .zip/.mbz files to Canvas.',
          :version => '1.0.0',
          :select_text => proc { I18n.t(:m2c_file_description, 'Moodle 1.9/2.x') },
          :settings => {
            :migration_partial => 'moodle_config',
            :worker=> 'CCWorker',
            :provides =>{:moodle_1_9=>Moodle::Converter, :moodle_2=>Moodle::Converter},
            :valid_contexts => %w{Account Course}
          }
  }
end
