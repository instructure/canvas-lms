module ParallelExclude
  FILES = [
    "spec/integration/files_spec.rb",
    "spec/apis/v1/calendar_events_api_spec.rb",
    "spec/models/attachment_spec.rb",
    "spec/lib/content_zipper_spec.rb",
    "vendor/plugins/respondus_lockdown_browser/spec_canvas/integration/respondus_ldb_spec.rb"
  ]

  test_files = FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/**/*_spec.rb')
  AVAILABLE_FILES = test_files.select { |file_name| FILES.include?(file_name) }
end
