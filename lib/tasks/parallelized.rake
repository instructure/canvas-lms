# Don't load rspec if running "rake gems:*"
unless ARGV.any? { |a| a =~ /\Agems/ }

  namespace :parallel do
    task :nonseleniumparallel, :count do |t, args|
      require "parallelized_specs"
      require File.expand_path(File.dirname(__FILE__) + '/parallel_exclude')
      count = args[:count]
      single_thread_files = ParallelExclude::FILES
      test_files = FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/**/*_spec.rb')
      single_thread_files.each { |filename| test_files.delete(filename) } #need to exclude these tests from running in parallel because they have dependencies that break the spces when run in parallel
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end

    task :nonselenium, :count do |t, args|
      Rake::Task['spec:single'].execute #first rake task to run the files that fail in parallel in a single thread

      #bug funky exit_codes resolved in ruby193p288 fix when resolved
      if File.zero?('tmp/parallel_log/rspec.failures')
        Rake::Task['parallel:nonseleniumparallel'].invoke(args[:count])
      else
        abort(`cat tmp/parallel_log/rspec.failures`)
      end

    end

    task :nonseleniumallparallel, :count do |t, args|
      require "parallelized_specs"
      count = args[:count]
      test_files = FileList['vendor/plugins/*/spec_canvas/**/*_spec.rb'].exclude('vendor/plugins/*/spec_canvas/selenium/*_spec.rb') + FileList['spec/**/*_spec.rb'].exclude('spec/selenium/**/*_spec.rb')
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      Rake::Task['parallel:spec'].invoke(count, '', '', test_files.join(' '))
    end

    task :selenium_tags, :test_files, :tag do |t, args|
      require "parallelized_specs"
      puts 'starting single threaded selenium specs'
      #fix better logging as tags matures
      output = `bundle exec rspec --format doc #{args[:test_files]} --tag #{args[:tag]}`
      puts output
      #bug funky exit_codes resolved in ruby193p288 fix when resolved
      output.match(/(\d) failure/).to_a.last.to_i != 0 ? exit(1) : puts('all non_parallel selenium specs passed')
    end

    task :selenium, :count, :build_section do |t, args|
      require "parallelized_specs"
      #used to split selenium builds when :build_section is set split it in two.
      test_files = FileList['spec/selenium/**/*_spec.rb'] + FileList['vendor/plugins/*/spec_canvas/selenium/*_spec.rb']
      test_files = test_files.to_a.sort_by! { |file| File.size(file) }

      args[:build_section].to_i == 0 ? section = nil : section = args[:build_section].to_i

      unless section.nil?
        test_files_a_sum = 0
        test_files_b_sum = 0
        test_files_a = []
        test_files_b = []
        test_files.each do |file|
          if test_files_a_sum < test_files_b_sum
            test_files_a << file
            test_files_a_sum += File.size(file)
          else
            test_files_b << file
            test_files_b_sum += File.size(file)
          end
        end

        case section
          when 1
            puts "INFO: running section 1"
            #runs upper half of selenium tests
            test_files = test_files_a
          when 2
            puts "INFO: running section 2"
            #runs lower half of selenium tests
            test_files = test_files_b
          else
            test_files = test_files_a + test_files_b
        end
      end
      test_files.map! { |f| "#{Rails.root}/#{f}" }
      test_files.each { |f| puts f }

      Rake::Task['parallel:selenium_tags'].invoke(test_files.join(' '), 'non_parallel')

      puts 'starting paralellized selenium spec runtime'
      Rake::Task['parallel:spec'].invoke(args[:count], '', '', test_files.join(' '))
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
