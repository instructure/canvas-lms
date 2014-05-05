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
  :name => lambda{ t :name, "BigBlueButton" },
  :description => lambda{ t :description, "BigBlueButton web conferencing support" },
  :website => 'http://bigbluebutton.org',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/big_blue_button_settings',
  :validator => 'BigBlueButtonValidator',
  :encrypted_settings => [:secret]
})
require_dependency 'cc/importer/cc_worker'
Canvas::Plugin.register 'canvas_cartridge_importer', :export_system, {
  :name => lambda{ I18n.t 'canvas_cartridge_name', 'Canvas Cartridge Importer' },
  :display_name => lambda{ I18n.t 'canvas_cartridge_display', 'Canvas Common Cartridge' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :description => lambda{ I18n.t :canvas_cartridge_description, 'This enables converting a canvas export to the intermediary json format to be imported' },
  :version => '1.0.0',
  :select_text => lambda{ I18n.t :canvas_cartridge_file_description, "Canvas Course Export Package" },
  :sort_order => 1,
  :settings => {
    :worker => 'CCWorker',
    :migration_partial => 'canvas_config',
    :requires_file_upload => true,
    :provides =>{:canvas_cartridge => CC::Importer::Canvas::Converter},
    :valid_contexts => %w{Account Course}
  },
}
require_dependency 'canvas/migration/worker/course_copy_worker'
Canvas::Plugin.register 'course_copy_importer', :export_system, {
        :name => lambda { I18n.t :course_copy_name, 'Copy Canvas Course' },
        :display_name => lambda { I18n.t :course_copy_display, 'Course Copy' },
        :author => 'Instructure',
        :author_website => 'http://www.instructure.com',
        :description => lambda { I18n.t :course_copy_description, 'Migration plugin for copying canvas courses' },
        :version => '1.0.0',
        :select_text => lambda { I18n.t :course_copy_file_description, "Copy a Canvas Course" },
        :sort_order => 0,
        :settings => {
                :worker => 'CourseCopyWorker',
                :requires_file_upload => false,
                :skip_conversion_step => true,
                :required_options_validator => Canvas::Migration::Validators::CourseCopyValidator,
                :required_settings => [:source_course_id],
                :valid_contexts => %w{Course}
        },
}
require_dependency 'canvas/migration/worker/zip_file_worker'
Canvas::Plugin.register 'zip_file_importer', :export_system, {
        :name => lambda { I18n.t :zip_file_name, '.zip file' },
        :display_name => lambda { I18n.t :zip_file_display, 'File Import' },
        :author => 'Instructure',
        :author_website => 'http://www.instructure.com',
        :description => lambda { I18n.t :zip_file_description, 'Migration plugin for unpacking .zip archives into course, group, or user files' },
        :version => '1.0.0',
        :select_text => lambda { I18n.t :zip_file_file_description, "Unzip .zip file into folder" },
        :sort_order => 2,
        :settings => {
                :worker => 'ZipFileWorker',
                :requires_file_upload => true,
                :no_selective_import => true,
                :required_options_validator => Canvas::Migration::Validators::ZipImporterValidator,
                :required_settings => [:source_folder_id],
                :valid_contexts => %w(Course Group User)
        },
}
Canvas::Plugin.register 'common_cartridge_importer', :export_system, {
  :name => lambda{ I18n.t :common_cartridge_name, 'Common Cartridge Importer' },
  :display_name => lambda{ I18n.t :common_cartridge_display, 'Common Cartridge' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :description => lambda{ I18n.t :common_cartridge_description, 'This enables converting a Common Cartridge packages in the intermediary json format to be imported' },
  :version => '1.0.0',
  :select_text => lambda{ I18n.t :common_cartridge_file_description, "Common Cartridge 1.0/1.1/1.2 Package" },
  :settings => {
    :worker => 'CCWorker',
    :migration_partial => 'cc_config',
    :requires_file_upload => true,
    :provides =>{:common_cartridge=>CC::Importer::Standard::Converter, 
                 :common_cartridge_1_0=>CC::Importer::Standard::Converter, 
                 :common_cartridge_1_1=>CC::Importer::Standard::Converter, 
                 :common_cartridge_1_2=>CC::Importer::Standard::Converter},
    :valid_contexts => %w{Account Course}
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

Canvas::Plugin.register('sessions', nil, {
  :name => lambda{ t :name, 'Sessions' },
  :description => lambda{ t :description, 'Manage session timeouts' },
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/sessions_timeout',
  :validator => 'SessionsValidator',
  :settings => nil
})

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

Canvas::Plugin.register('crocodoc', :previews, {
  :name => lambda { t :name, 'Crocodoc' },
  :description => lambda { t :description, 'Enable Crocodoc as a document preview option' },
  :website => 'https://crocodoc.com/',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/crocodoc_settings',
  :settings => nil
})

Canvas::Plugin.register('canvadocs', :previews, {
  :name => lambda { t :name, 'Canvadocs' },
  :description => lambda { t :description, 'Enable Canvadocs (compatible with Box View) as a document preview option' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/canvadocs_settings',
  :settings => nil
})

Canvas::Plugin.register('account_reports', nil, {
  :name => lambda{ t :name, 'Account Reports' },
  :description => lambda{ t :description, 'Select account reports' },
  :website => 'http://www.instructure.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/account_report_settings',
  :settings => nil,
  :validator => 'AccountReportsValidator'
})
Canvas::Plugin.register('app_center', nil, {
    :name => lambda{ t :name, 'App Center' },
    :description => lambda{ t :description, 'App Center for tracking/installing external tools in Canvas' },
    :settings_partial => 'plugins/app_center_settings',
    :settings => {
        :base_url => 'https://www.edu-apps.org',
        :token => nil,
        :apps_index_endpoint => '/api/v1/apps',
        :app_reviews_endpoint => '/api/v1/apps/:id/reviews'
    },
    :validator => 'AppCenterValidator'
})

