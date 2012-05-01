# Don't load rspec if running "rake gems:*"
unless ARGV.any? { |a| a =~ /\Agems/ }

  namespace :parallel do
    task :nonselenium, :count do |t, args|
      require "parallelized_specs"
      count = args[:count]
      test_files = FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/*_spec.rb')
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end

    task :selenium, :count do |t, args|
      require "parallelized_specs"
      count = args[:count]
      test_files = FileList['spec/selenium/*_spec.rb'] + FileList['vendor/plugins/*/spec_canvas/selenium/*_spec.rb']
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