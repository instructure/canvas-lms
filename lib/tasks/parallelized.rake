# Don't load rspec if running "rake gems:*"
unless ARGV.any? { |a| a =~ /\Agems/ }

  namespace :parallel do
    task :nonseleniumparallel, :count do |t, args|
      require "parallelized_specs"
      count = args[:count]
      single_thread_files =
          [
              'vendor/plugins/wiziq/spec_canvas/aglive_com_util_spec.rb',
              'spec/controllers/files_controller_spec.rb',
              'vendor/plugins/multiple_root_accounts/spec_canvas/integration/quotas_spec.rb',
              'vendor/plugins/wiziq/spec_canvas/wiziq_conference_spec.rb',
              'vendor/plugins/multiple_root_accounts/spec_canvas/lib/shard_importer_spec.rb',
              'vendor/plugins/respondus_soap_endpoint/spec_canvas/integration/respondus_endpoint_spec.rb',
              'spec/apis/api_spec_helper.rb',
              'spec/apis/general_api_spec.rb',
              'spec/apis/user_content_spec.rb',
              'spec/apis/v1/groups_api_spec.rb',
              'spec/apis/v1/submissions_api_spec.rb',
              'spec/integration/files_spec.rb',
              'spec/lib/acts_as_list.rb',
              'spec/lib/content_zipper_spec.rb',
              'spec/lib/turnitin_spec.rb',
              'spec/models/attachment_spec.rb',
              'spec/models/course_spec.rb',
              'spec/models/eportfolio_entry_spec.rb',
              'spec/models/media_object_spec.rb',
              'spec/models/zip_file_import_spec.rb'
          ]
      test_files = FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/**/*_spec.rb')
      single_thread_files.each { |filename| test_files.delete(filename) } #need to exclude these tests from running in parallel because they have dependencies that break the spces when run in parallel
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end

    task :nonselenium, :count do |t, args|
      Rake::Task['spec:single'].invoke #first rake task to run the files that fail in parallel in a single thread
      Rake::Task['parallel:nonseleniumparallel'].invoke(args[:count])
    end

    task :selenium, :count do |t, args|
      require "parallelized_specs"
      count = args[:count]
      test_files = FileList['spec/selenium/**/*_spec.rb'] + FileList['vendor/plugins/*/spec_canvas/selenium/*_spec.rb']
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end

    task :pattern, :count, :file_pattern do |t, args|
      require "parallelized_specs"
      count = args[:count]
      file_pattern = args[:file_pattern]
      if count.nil? || file_pattern.nil?
        raise "Must specify a thread count and file pattern"
      end
      test_files = FileList[file_pattern]
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end
  end
end