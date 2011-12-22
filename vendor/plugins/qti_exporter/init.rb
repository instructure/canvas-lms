Rails.configuration.to_prepare do
  python_converter_found = Qti.migration_executable ? true : false

  Canvas::Plugin.register :qti_converter, :export_system, {
          :name => proc { t(:name, 'QTI Converter') },
          :author => 'Instructure',
          :description => 'This enables converting QTI .zip files to Canvas quiz json.',
          :version => '1.0.0',
          :settings_partial => 'plugins/qti_converter_settings',
          :select_text => proc { t(:file_description, 'QTI .zip file') },
          :settings => {
            :enabled => python_converter_found,
            :migration_partial => 'qti_config',
            :worker=> 'QtiWorker',
            :provides =>{:qti=>Qti::Converter, 
                         :webct=>Qti::Converter, # It can import WebCT Quizzes
            }
          },
          :validator => 'QtiPluginValidator'
  }
end
