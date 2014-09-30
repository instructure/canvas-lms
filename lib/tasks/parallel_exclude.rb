module ParallelExclude
  FILES = [
    "spec/apis/v1/calendar_events_api_spec.rb",
    "spec/integration/files_spec.rb",
    "spec/models/media_object_spec.rb",
    "spec/lib/content_zipper_spec.rb",
    "spec/lib/file_in_context_spec.rb",
    "vendor/plugins/respondus_lockdown_browser/spec_canvas/integration/respondus_ldb_spec.rb",
    "spec/models/attachment_spec.rb"
  ]

  test_files = FileList['{gems,vendor}/plugins/*/spec_canvas/**/*_spec.rb'].exclude(%r'spec_canvas/selenium') + FileList['spec/**/*_spec.rb'].exclude(%r'spec/selenium')
  AVAILABLE_FILES = FILES.select{|file_name| test_files.include?(file_name) }
end
