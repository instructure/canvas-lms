# CANVAS-240 Add WebCT wording to new Import Content page
# This overrides Canvas' own course_copy_importer in /lib/canvas/plugins/default_plugins.rb
Rails.configuration.to_prepare do
  require_dependency 'canvas/migration/worker/course_copy_worker'
  Canvas::Plugin.register 'course_copy_importer', :export_system, {
      :name => lambda { I18n.t :course_copy_name, 'Copy Canvas/WebCT Course' },
      :author => 'Instructure',
      :author_website => 'http://www.instructure.com',
      :description => lambda { I18n.t :course_copy_description, 'Migration plugin for copying Canvas or WebCT courses' },
      :version => '1.0.0-sfu',
      :select_text => lambda { I18n.t :course_copy_file_description, "Copy a Canvas or WebCT Course" },
      :settings => {
          :worker => 'CourseCopyWorker',
          :requires_file_upload => false,
          :skip_conversion_step => true,
          :required_options_validator => Canvas::Migration::Validators::CourseCopyValidator,
          :required_settings => [:source_course_id]
      },
  }
end
