module ParallelExclude
  FILES = [
      'spec/apis/v1/submissions_api_spec.rb',
      'vendor/plugins/wiziq/spec_canvas/aglive_com_util_spec.rb',
      'spec/controllers/files_controller_spec.rb',
      'vendor/plugins/multiple_root_accounts/spec_canvas/integration/quotas_spec.rb',
      'vendor/plugins/wiziq/spec_canvas/wiziq_conference_spec.rb',
      'vendor/plugins/multiple_root_accounts/spec_canvas/lib/shard_importer_spec.rb',
      'vendor/plugins/respondus_soap_endpoint/spec_canvas/integration/respondus_endpoint_spec.rb',
      'vendor/plugins/multiple_root_accounts/spec_canvas/models/attachment_spec.rb',
      'vendor/plugins/webct_scraper/spec_canvas/lib/models/bulk_course_migration_spec.rb',
      'spec/apis/api_spec_helper.rb',
      'spec/apis/general_api_spec.rb',
      'spec/apis/user_content_spec.rb',
      'spec/apis/v1/groups_api_spec.rb',
      'spec/apis/v1/courses_api_spec.rb',
      'spec/apis/v1/collections_spec.rb',
      'spec/apis/auth_spec.rb',
      'spec/integration/files_spec.rb',
      'spec/lib/acts_as_list.rb',
      'spec/lib/content_zipper_spec.rb',
      'spec/lib/turnitin_spec.rb',
      'spec/models/attachment_spec.rb',
      'spec/models/course_spec.rb',
      'spec/models/eportfolio_entry_spec.rb',
      'spec/models/media_object_spec.rb',
      'spec/models/zip_file_import_spec.rb',
      'spec/models/content_migration_spec.rb',
      'spec/models/collections_spec.rb',
      'spec/lib/canvas/http_spec.rb',
      'spec/migrations/count_existing_collection_items_and_followers_spec.rb'
  ]

  test_files = FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/**/*_spec.rb')
  AVAILABLE_FILES = test_files.select { |file_name| FILES.include?(file_name) }
end
