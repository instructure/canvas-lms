module QtiExporter
  class Engine < Rails::Engine
    config.autoload_paths << File.expand_path(File.join(__FILE__, "../.."))

    config.to_prepare do
      python_converter_found = Qti.migration_executable ? true : false

      Canvas::Plugin.register :qti_converter, :export_system, {
              :name => proc { I18n.t(:qti_name, 'QTI Converter') },
              :display_name => proc { I18n.t(:qti_display, 'QTI') },
              :author => 'Instructure',
              :description => 'This enables converting QTI .zip files to Canvas quiz json.',
              :version => '1.0.0',
              :settings_partial => 'plugins/qti_converter_settings',
              :select_text => proc { I18n.t(:qti_file_description, 'QTI .zip file') },
              :settings => {
                :enabled => python_converter_found,
                :migration_partial => 'qti_config',
                :worker=> 'QtiWorker',
                :requires_file_upload => true,
                :provides =>{:qti=>Qti::Converter,
                             :webct=>Qti::Converter, # It can import WebCT Quizzes
                },
                :valid_contexts => %w{Account Course}
              },
              :validator => 'QtiPluginValidator'
      }
    end
  end
end
