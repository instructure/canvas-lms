#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

Canvas::Plugin.register('clever', nil,
  name: 'Clever',
  description: -> { t :description, 'Clever Login' },
  website: 'https://clever.com',
  author: 'Instructure',
  author_website: 'http://www.instructure.com',
  version: '1.0.0',
  settings_partial: 'plugins/clever_settings',
  encrypted_settings: [:client_secret]
)
Canvas::Plugin.register('facebook', nil,
  name: 'Facebook',
  description: -> { t :description, 'Facebook Login' },
  website: 'http://www.facebook.com',
  author: 'Instructure',
  author_website: 'http://www.instructure.com',
  version: '2.0.0',
  settings_partial: 'plugins/facebook_settings',
  encrypted_settings: [:app_secret]
)
Canvas::Plugin.register('github', nil,
  name: 'GitHub',
  description: -> { t :description, 'Github Login' },
  website: 'https://github.com',
  author: 'Instructure',
  author_website: 'http://www.instructure.com',
  version: '1.0.0',
  settings_partial: 'plugins/github_settings',
  encrypted_settings: [:client_secret]
)
Canvas::Plugin.register('linked_in', nil,
  name: 'LinkedIn',
  description: -> { t :description, 'LinkedIn integration' },
  website: 'http://www.linkedin.com',
  author: 'Instructure',
  author_website: 'http://www.instructure.com',
  version: '1.0.0',
  settings_partial: 'plugins/linked_in_settings',
  validator: 'LinkedInValidator',
  encrypted_settings: [:client_secret]
)
Canvas::Plugin.register('microsoft', nil,
  name: 'Microsoft',
  description: -> { t :description, 'Microsoft Login'},
  website: 'https://apps.dev.microsoft.com',
  author: 'Siimpl',
  author_website: 'https://siimpl.io',
  version: '1.0.0',
  settings_partial: 'plugins/microsoft_settings',
  encrypted_settings: [:application_secret]
)
Canvas::Plugin.register('diigo', nil, {
  :name => lambda{ t :name, 'Diigo' },
  :description => lambda{ t :description, 'Diigo integration' },
  :website => 'https://www.diigo.com',
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/diigo_settings',
  :validator => 'DiigoValidator'
})
Canvas::Plugin.register('twitter', nil,
  name: 'Twitter',
  description: -> { t :description, 'Twitter notifications' },
  website: 'http://www.twitter.com',
  author: 'Instructure',
  author_website: 'http://www.instructure.com',
  version: '1.0.0',
  settings_partial: 'plugins/twitter_settings',
  validator: 'TwitterValidator',
  encrypted_settings: [:consumer_secret]
)
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
Canvas::Plugin.register('google_drive', :collaborations,
                        {
                          name: -> { t :name, 'Google Drive' },
                          description: -> { t :description, 'Google Drive file sharing' },
                          website: 'http://drive.google.com',
                          author: 'Instructure',
                          author_website: 'http://www.instructure.com',
                          version: '1.0.0',
                          settings_partial: 'plugins/google_drive_settings',
                          validator: 'GoogleDriveValidator',
                          encrypted_settings: [:client_secret]
                        }
                       )
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
Canvas::Plugin.register('mathman', nil, {
  :name => lambda{ t :name, 'MathMan' },
  :description => lambda{ t :description, 'A simple microservice that converts LaTeX formulae to MathML and SVG'},
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings_partial => 'plugins/mathman_settings',
  :settings => {
    use_for_svg: false,
    use_for_mml: false
  }
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
  :select_text => lambda{ I18n.t :common_cartridge_file_description, "Common Cartridge 1.x Package" },
  :settings => {
    :worker => 'CCWorker',
    :migration_partial => 'cc_config',
    :requires_file_upload => true,
    :provides =>{:common_cartridge=>CC::Importer::Standard::Converter,
                 :common_cartridge_1_0=>CC::Importer::Standard::Converter,
                 :common_cartridge_1_1=>CC::Importer::Standard::Converter,
                 :common_cartridge_1_2=>CC::Importer::Standard::Converter,
                 :common_cartridge_1_3=>CC::Importer::Standard::Converter},
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
Canvas::Plugin.register('i18n', nil, {
    :name => lambda{ t :name, 'I18n' },
    :description => lambda{ t :description, 'Custom Locales' },
    :website => 'https://www.instructure.com',
    :author => 'Instructure',
    :author_website => 'http://www.instructure.com',
    :version => '1.0.0',
    :settings_partial => 'plugins/i18n_settings',
    :validator => 'I18nValidator'
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
        :base_url => 'https://www.eduappcenter.com',
        :token => nil,
        :apps_index_endpoint => '/api/v1/lti_apps',
        :app_reviews_endpoint => '/api/v1/lti_apps/:id/reviews'
    },
    :validator => 'AppCenterValidator'
})
Canvas::Plugin.register('pandapub', nil, {
  :name => lambda{ t :name, 'PandaPub' },
  :description => lambda{ t :description, 'Pub/Sub service' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings => {
    :base_url => nil,
    :application_id => nil,
    :key_id => nil,
    :key_secret => nil
  },
  :settings_partial => 'plugins/panda_pub_settings',
  :validator => 'PandaPubValidator'
})
Canvas::Plugin.register('vericite', nil, {
  :name => lambda{ t :name, 'VeriCite' },
  :description => lambda{ t :description, 'Plagiarism detection service.' },
  :author => 'VeriCite',
  :author_website => 'http://www.vericite.com',
  :version => '1.0.0',
  :settings => {
    :account_id => nil,
    :shared_secret => nil,
    :host => 'api.vericite.com',
    :comments => nil,
    :pledge => nil,
    :release_to_students => 'immediate',
    :exclude_quotes => true,
    :exclude_self_plag => true,
    :store_in_index => true,
    :show_preliminary_score => false,
  },
  :settings_partial => 'plugins/vericite_settings'
})
Canvas::Plugins::TicketingSystem.register!
Canvas::Plugin.register('live_events', nil, {
  :name => lambda{ t :name, 'Live Events' },
  :description => lambda{ t :description, 'Service for real-time events.' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings => {
    :use_consul => false,
    :kinesis_stream_name => nil,
    :aws_access_key_id => nil,
    :aws_secret_access_key => nil,
    :aws_region => 'us-east-1',
    :aws_endpoint => nil,
  },
  :encrypted_settings => [ :aws_secret_access_key ],
  :settings_partial => 'plugins/live_events_settings',
  :validator => 'LiveEventsValidator'
})
Canvas::Plugin.register('live_events', nil, {
  :name => lambda{ t :name, 'Live Events' },
  :description => lambda{ t :description, 'Service for real-time events.' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '1.0.0',
  :settings => {
    :kinesis_stream_name => nil,
    :aws_access_key_id => nil,
    :aws_secret_access_key => nil,
    :aws_region => 'us-east-1',
    :aws_endpoint => nil,
  },
  :encrypted_settings => [ :aws_secret_access_key ],
  :settings_partial => 'plugins/live_events_settings',
  :validator => 'LiveEventsValidator'
})
Canvas::Plugin.register('inst_fs', nil, {
  :name =>lambda{ t :name, 'Inst-FS' },
  :description => lambda{ t :description, 'File service that proxies for S3.' },
  :author => 'Instructure',
  :author_website => 'http://www.instructure.com',
  :version => '0.0.1',
  :settings => nil,
  :settings_partial => 'plugins/inst_fs_settings'
})
require_dependency 'canvas/plugins/address_book'
