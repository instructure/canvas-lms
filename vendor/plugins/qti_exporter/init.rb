require 'canvas/plugin'
require File.dirname(__FILE__) + '/lib/qti_exporter'

python_converter_found = Qti.migration_executable ? true : false

Canvas::Plugin.register :qti_exporter, nil, {
  :name =>'QTI Exporter',
  :author => 'Bracken Mosbacker',
  :description => 'This enables exporting QTI .zip files to Canvas quiz json.',
  :version => '1.0.0',
  :settings_partial => 'plugins/qti_exporter_settings',
  :settings => {:enabled=>python_converter_found, :worker=>'QtiWorker'}
}
