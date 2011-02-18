Dir.glob('lib/canvas/plugins/validators/*').each do |file|
  require_dependency file
end

Canvas::Plugin.register('kaltura', nil, {
  :description => 'Kaltura video/audio recording and playback',
  :website => 'http://corp.kaltura.com',
  :author => 'instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/kaltura_settings',
  :validator => 'KalturaValidator'
})
Canvas::Plugin.register('dim_dim', :web_conferencing, {
  :description => 'DimDim web conferencing support',
  :website => 'http://www.dimdim.com',
  :author => 'instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/dim_dim_settings'
})
Canvas::Plugin.register('wimba', :web_conferencing, {
  :description => 'Wimba web conferencing support',
  :website => 'http://www.wimba.com',
  :author => 'instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/wimba_settings',
  :validator => 'WimbaValidator',
  :encrypted_settings => [:password]
})
