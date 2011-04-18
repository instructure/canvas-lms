Dir.glob('lib/canvas/plugins/validators/*').each do |file|
  require_dependency file
end

Canvas::Plugin.register('kaltura', nil, {
  :description => 'Kaltura video/audio recording and playback',
  :website => 'http://corp.kaltura.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/kaltura_settings',
  :validator => 'KalturaValidator'
})
Canvas::Plugin.register('dim_dim', :web_conferencing, {
  :description => 'DimDim web conferencing support',
  :website => 'http://www.dimdim.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/dim_dim_settings'
})
Canvas::Plugin.register('wimba', :web_conferencing, {
  :description => 'Wimba web conferencing support',
  :website => 'http://www.wimba.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/wimba_settings',
  :validator => 'WimbaValidator',
  :encrypted_settings => [:password]
})
Canvas::Plugin.register('error_reporting', :error_reporting, {
  :description => 'Default error reporting mechanisms',
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/error_reporting_settings'
})
require_dependency 'cc/importer/cc_worker'
Canvas::Plugin.register 'common_cartridge_importer', :export_system, {
  :name => 'Common Cartridge Importer',
  :author => 'Instructure',
  :description => 'This enables converting a canvas CC export to the intermediary json format to be imported',
  :version => '1.0.0',
  :settings => {
    :worker=>'CCWorker',
    :migration_partial => 'cc_config',
    :select_text => "Canvas Course Export"
  }
}
