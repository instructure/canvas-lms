Dir.glob('lib/canvas/plugins/validators/*').each do |file|
  require_dependency file
end

Canvas::Plugin.register('kaltura', nil, {
  :description => 'Kaltura video/audio recording and playback',
  :website => 'http://corp.kaltura.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/kaltura_settings',
  :validator => 'KalturaValidator'
})
Canvas::Plugin.register('dim_dim', :web_conferencing, {
  :description => 'DimDim web conferencing support',
  :website => 'http://www.dimdim.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/dim_dim_settings'
})
Canvas::Plugin.register('wimba', :web_conferencing, {
  :description => 'Wimba web conferencing support',
  :website => 'http://www.wimba.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/wimba_settings',
  :settings => {:timezone => 'Eastern Time (US & Canada)'},
  :validator => 'WimbaValidator',
  :encrypted_settings => [:password]
})
Canvas::Plugin.register('error_reporting', :error_reporting, {
  :description => 'Default error reporting mechanisms',
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/error_reporting_settings'
})
Canvas::Plugin.register('big_blue_button', :web_conferencing, {
  :description => 'Big Blue Button web conferencing support',
  :website => 'http://bigbluebutton.org',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/big_blue_button_settings',
  :validator => 'BigBlueButtonValidator',
  :encrypted_settings => [:secret]
})
require_dependency 'cc/importer/cc_worker'
Canvas::Plugin.register 'common_cartridge_importer', :export_system, {
  :name => 'Common Cartridge Importer',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :description => 'This enables converting a canvas CC export to the intermediary json format to be imported',
  :version => '1.0.0',
  :settings => {
    :worker=>'CCWorker',
    :migration_partial => 'cc_config',
    :select_text => "Canvas Course Export"
  }
}
Canvas::Plugin.register('grade_export', :sis, {
  :name => "Grade Export",
  :description => 'Grade Export for SIS',
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/grade_export_settings',
  :settings => { :enabled => "false",
                 :publish_endpoint => "",
                 :wait_for_success => "no",
                 :success_timeout => "600",
                 :format_type => "instructure_csv" }
})
