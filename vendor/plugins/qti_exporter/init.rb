Rails.configuration.to_prepare do
  require_dependency 'qti_exporter'
  python_converter_found = Qti.migration_executable ? true : false

  Canvas::Plugin.register :qti_exporter, :export_system, {
          :name => proc { t(:name, 'QTI Exporter') },
          :author => 'Instructure',
          :description => 'This enables exporting QTI .zip files to Canvas quiz json.',
          :version => '1.0.0',
          :settings_partial => 'plugins/qti_exporter_settings',
          :select_text => proc { t(:file_description, 'QTI .zip file') },
          :settings => {
            :enabled => python_converter_found,
            :migration_partial => 'qti_config',
            :worker=> 'QtiWorker',
            :provides =>{:qti=>Qti::QtiExporter, 
                         :webct=>Qti::QtiExporter, # It can import WebCT Quizzes
            }
          },
          :validator => 'QtiPluginValidator'
  }
end
