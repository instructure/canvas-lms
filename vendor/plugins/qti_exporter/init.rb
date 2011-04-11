Rails.configuration.to_prepare do
  require_dependency 'qti_exporter'
  python_converter_found = Qti.migration_executable ? true : false

  Canvas::Plugin.register :qti_exporter, nil, {
          :name =>'QTI Exporter',
          :author => 'Instructure',
          :description => 'This enables exporting QTI .zip files to Canvas quiz json.',
          :version => '1.0.0',
          :settings_partial => 'plugins/qti_exporter_settings',
          :settings => {
          :enabled=>python_converter_found, :worker=>'QtiWorker', :select_text=>'QTI .zip file'},
          :validator => 'QtiPluginValidator'
  }
end
