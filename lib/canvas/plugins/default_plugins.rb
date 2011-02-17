Canvas::Plugin.register('kaltura', nil, {
  :description => 'Kaltura video/audio recording and playback',
  :website => 'http://www.instructure.com',
  :author => 'instructure',
  :author_website => 'http://www.instructure.com',
  :version => 1.0,
  :settings_partial => 'plugins/kaltura_settings',
  :validator => 'KalturaValidator'
})