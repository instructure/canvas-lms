Rails.configuration.to_prepare do

  Canvas::Plugin.register :moodle_converter, :export_system, {
          :name => proc { t(:name, 'Moodle Importer') },
          :author => 'Divergent Logic',
          :description => 'This enables importing Moodle 1.9 .zip files to Canvas.',
          :version => '1.0.0',
          :select_text => proc { t(:file_description, 'Moodle 1.9 .zip file') },
          :settings => {
            :migration_partial => 'moodle_config',
            :worker=> 'CCWorker',
            :provides =>{:moodle_1_9=>Moodle::Converter}
          }
  }
end
