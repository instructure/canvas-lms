Dir.glob('lib/canvas/plugins/validators/*').each do |file|
  require_dependency file
end

Canvas::Plugin.register('facebook', nil, {
  :name => lambda{ t :name, 'Facebook' },
  :description => lambda{ t :description, 'Canvas Facebook application' },
  :website => 'http://www.facebook.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/facebook_settings',
  :validator => 'FacebookValidator'
})
Canvas::Plugin.register('linked_in', nil, {
  :name => lambda{ t :name, 'LinkedIn' },
  :description => lambda{ t :description, 'LinkedIn integration' },
  :website => 'http://www.linkedin.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/linked_in_settings',
  :validator => 'LinkedInValidator'
})
Canvas::Plugin.register('twitter', nil, {
  :name => lambda{ t :name, 'Twitter' },
  :description => lambda{ t :description, 'Twitter notifications' },
  :website => 'http://www.twitter.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/twitter_settings',
  :validator => 'TwitterValidator'
})
Canvas::Plugin.register('scribd', nil, {
  :name => lambda{ t :name, 'Scribd' },
  :description => lambda{ t :description, 'Scribd document previews' },
  :website => 'http://www.scribd.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/scribd_settings',
  :validator => 'ScribdValidator'
})
Canvas::Plugin.register('etherpad', :collaborations, {
  :name => lambda{ t :name, 'EtherPad' },
  :description => lambda{ t :description, 'EtherPad document sharing' },
  :website => 'http://www.etherpad.org',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/etherpad_settings',
  :validator => 'EtherpadValidator'
})
Canvas::Plugin.register('google_docs', :collaborations, {
  :name => lambda{ t :name, 'Google Docs' },
  :description => lambda{ t :description, 'Google Docs document sharing' },
  :website => 'http://docs.google.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/google_docs_settings',
  :validator => 'GoogleDocsValidator'
})
Canvas::Plugin.register('kaltura', nil, {
  :name => lambda{ t :name, 'Kaltura' },
  :description => lambda{ t :description, 'Kaltura video/audio recording and playback'},
  :website => 'http://corp.kaltura.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/kaltura_settings',
  :validator => 'KalturaValidator'
})
Canvas::Plugin.register('dim_dim', :web_conferencing, {
  :name => lambda{ t :name, "DimDim" },
  :description => lambda{ t :description, "DimDim web conferencing support" },
  :website => 'http://www.dimdim.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/dim_dim_settings'
})
Canvas::Plugin.register('wimba', :web_conferencing, {
  :name => lambda{ t :name, "Wimba" },
  :description => lambda{ t :description, "Wimba web conferencing support" },
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
  :name => lambda{ t :name, 'Error Reporting' },
  :description => lambda{ t :description, 'Default error reporting mechanisms' },
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/error_reporting_settings'
})
Canvas::Plugin.register('big_blue_button', :web_conferencing, {
  :name => lambda{ t :name, "Big Blue Button" },
  :description => lambda{ t :description, "Big Blue Button web conferencing support" },
  :website => 'http://bigbluebutton.org',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/big_blue_button_settings',
  :validator => 'BigBlueButtonValidator',
  :encrypted_settings => [:secret]
})
Canvas::Plugin.register('tinychat', nil, {
  :name => lambda{ t :name, 'Tinychat' },
  :description => lambda{ t :description, 'Tinychat chat room'},
  :website => 'http://www.tinychat.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/tinychat_settings',
  :validator => 'TinychatValidator'
})
require_dependency 'cc/importer/cc_worker'
Canvas::Plugin.register 'canvas_cartridge_importer', :export_system, {
  :name => lambda{ t :name, 'Canvas Cartridge Importer' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :description => lambda{ t :description, 'This enables converting a canvas export to the intermediary json format to be imported' },
  :version => '1.0.0',
  :select_text => lambda{ t :file_description, "Canvas Course Export Package" },
  :settings => {
    :worker => 'CCWorker',
    :migration_partial => 'canvas_config',
    :provides =>{:canvas_cartridge => CC::Importer::Canvas::Converter}
  },
}
Canvas::Plugin.register 'common_cartridge_importer', :export_system, {
  :name => lambda{ t :name, 'Common Cartridge Importer' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :description => lambda{ t :description, 'This enables converting a Common Cartridge packages in the intermediary json format to be imported' },
  :version => '1.0.0',
  :select_text => lambda{ t :file_description, "Common Cartridge 1.0/1.1/1.2 Package" },
  :settings => {
    :worker => 'CCWorker',
    :migration_partial => 'cc_config',
    :provides =>{:common_cartridge=>CC::Importer::Standard::Converter, 
                 :common_cartridge_1_0=>CC::Importer::Standard::Converter, 
                 :common_cartridge_1_1=>CC::Importer::Standard::Converter, 
                 :common_cartridge_1_2=>CC::Importer::Standard::Converter},
  },
}
Canvas::Plugin.register('grade_export', :sis, {
  :name => lambda{ t :name, "Grade Export" },
  :description => lambda{ t :description, 'Grade Export for SIS' },
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/grade_export_settings',
  :settings => { :publish_endpoint => "",
                 :wait_for_success => "no",
                 :success_timeout => "600",
                 :format_type => "instructure_csv" }
})
Canvas::Plugin.register('sis_import', :sis, {
  :name => lambda{ t :name, 'SIS Import' },
  :description => lambda{ t :description, 'Import SIS Data' },
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/sis_import_settings',
  :settings => { :parallelism => 1,
                 :minimum_rows_for_parallel => 1000,
                 :queue_for_parallel_jobs => nil }
})
if Attachment.s3_storage?
  Canvas::Plugin.register('s3', nil, {
      :name => lambda { t :name, 'S3' },
      :description => lambda { t :description, 'S3 storage for files' },
      :website => 'http://www.instructure.com',
      :author => 'Instructure',
      :author_website => 'http://www.instructure.com',
      :version => '1.0.0',
      :settings_partial => 'plugins/s3_settings',
      :settings => Attachment.s3_config
  })
end
Canvas::Plugin.register('assignment_freezer', nil, {
  :name => lambda{ t :name, 'Assignment Property Freezer' },
  :description => lambda{ t :description, 'Freeze Assignment Properties on Copy' },
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/assignment_freezer_settings',
  :settings => nil
})
Canvas::Plugin.register('embedly', nil, {
  :name => lambda{ t :name, 'Embedly Integration' },
  :description => lambda{ t :description, 'Pull Embedly info for Collections' },
  :website => 'http://embed.ly/',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/embedly_settings',
  :settings => nil
})
